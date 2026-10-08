import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../models/job.dart';

class OpportunityLocationResult {
  const OpportunityLocationResult({
    required this.jobs,
    required this.accuracyMeters,
    required this.message,
  });

  final List<Job> jobs;
  final double accuracyMeters;
  final String message;
}

class LocationService {
  static const _valhallaBase = 'https://valhalla1.openstreetmap.de';
  static const _osrmBase = 'https://router.project-osrm.org';
  static const _nominatimBase = 'https://nominatim.openstreetmap.org';

  Future<OpportunityLocationResult> enrichJobs(List<Job> jobs) async {
    final position = await _position();
    return _enrichFromOrigin(
      jobs,
      _Origin(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        manual: false,
      ),
    );
  }

  Future<OpportunityLocationResult> enrichJobsFromAddress(
    List<Job> jobs,
    String address,
  ) async {
    final normalized = address.trim();
    if (normalized.length < 5) {
      throw Exception('Informe rua, número, cidade e UF.');
    }
    final point = await _geocodeText(normalized);
    if (point == null) {
      throw Exception(
        'Não foi possível localizar esse endereço. Inclua número, cidade e UF.',
      );
    }
    return _enrichFromOrigin(
      jobs,
      _Origin(
        latitude: point.$1,
        longitude: point.$2,
        accuracy: 0,
        manual: true,
      ),
    );
  }

  Future<OpportunityLocationResult> _enrichFromOrigin(
    List<Job> jobs,
    _Origin origin,
  ) async {
    if (jobs.isEmpty) {
      return const OpportunityLocationResult(
        jobs: <Job>[],
        accuracyMeters: 0,
        message: 'Nenhuma oportunidade disponível.',
      );
    }

    final resolved = <_ResolvedJob>[];
    final untouched = <int, Job>{};

    for (var i = 0; i < jobs.length; i++) {
      var job = jobs[i];
      var lat = job.latitude;
      var lng = job.longitude;

      if (lat == null || lng == null) {
        final geocoded = await _geocode(job);
        if (geocoded != null) {
          lat = geocoded.$1;
          lng = geocoded.$2;
          job = job.copyWith(latitude: lat, longitude: lng);
        }
      }

      if (lat == null || lng == null) {
        untouched[i] = job;
      } else {
        resolved.add(
          _ResolvedJob(
            index: i,
            job: job,
            latitude: lat,
            longitude: lng,
          ),
        );
      }
    }

    final routeDistances = await _valhallaDistances(origin, resolved);
    final missing = resolved
        .where((item) => !routeDistances.containsKey(item.index))
        .toList();
    if (missing.isNotEmpty) {
      final osrm = await _osrmDistances(origin, missing);
      routeDistances.addAll(osrm);
    }

    final output = List<Job>.from(jobs);
    for (final item in resolved) {
      final routed = routeDistances[item.index];
      if (routed != null) {
        output[item.index] = item.job.copyWith(
          distanceKm: routed,
          distanceMode: 'road',
        );
      } else {
        output[item.index] = item.job.copyWith(
          distanceKm: _haversine(
            origin.latitude,
            origin.longitude,
            item.latitude,
            item.longitude,
          ),
          distanceMode: 'straight',
        );
      }
    }
    untouched.forEach((index, job) => output[index] = job);

    output.sort((a, b) {
      final da = a.distanceKm ?? double.infinity;
      final db = b.distanceKm ?? double.infinity;
      return da.compareTo(db);
    });

    final accuracy = origin.accuracy;
    final accuracyLabel = accuracy >= 1000
        ? '±' + (accuracy / 1000).toStringAsFixed(1) + ' km'
        : '±' + accuracy.round().toString() + ' m';
    final message = origin.manual
        ? 'Ponto de partida manual aplicado. Distâncias calculadas por rota rodoviária.'
        : (accuracy > 500
            ? 'Localização aproximada do aparelho (' +
                accuracyLabel +
                '). As distâncias usam rota rodoviária; ative localização precisa/GPS ou informe um endereço manual.'
            : 'Localização precisa (' +
                accuracyLabel +
                '). Distâncias calculadas por rota rodoviária.');

    return OpportunityLocationResult(
      jobs: output,
      accuracyMeters: accuracy,
      message: message,
    );
  }

  Future<Position> _position() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception(
        'Ative a localização/GPS do aparelho para calcular a distância das vagas.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception(
        'Permita o acesso à localização para calcular a distância das vagas.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'A localização está bloqueada para o TurnoPronto. Libere a permissão nas configurações do Android.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 18),
      ),
    );
  }

  Future<(double, double)?> _geocode(Job job) async {
    final query = <String>[
      if (job.address.trim().isNotEmpty) job.address.trim(),
      if (job.city.trim().isNotEmpty) job.city.trim(),
      if (job.state.trim().isNotEmpty) job.state.trim(),
      'Brasil',
    ].join(', ');
    return _geocodeText(query);
  }

  Future<(double, double)?> _geocodeText(String text) async {
    var query = text.trim();
    if (query.length < 5) return null;
    if (!query.toLowerCase().contains('brasil')) {
      query += ', Brasil';
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final uri = Uri.parse(
        _nominatimBase +
            '/search?format=jsonv2&limit=1&countrycodes=br&q=' +
            Uri.encodeQueryComponent(query),
      );
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'TurnoPronto-Android/0.2 (turnopronto.com.br)',
      );
      final response = await request.close().timeout(
            const Duration(seconds: 10),
          );
      if (response.statusCode != 200) return null;
      final raw = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(raw);
      if (decoded is! List || decoded.isEmpty || decoded.first is! Map) {
        return null;
      }
      final row = Map<String, dynamic>.from(decoded.first as Map);
      final lat = double.tryParse(row['lat']?.toString() ?? '');
      final lng = double.tryParse(row['lon']?.toString() ?? '');
      if (lat == null || lng == null) return null;
      return (lat, lng);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<int, double>> _valhallaDistances(
    _Origin origin,
    List<_ResolvedJob> items,
  ) async {
    final result = <int, double>{};
    if (items.isEmpty) return result;

    for (var start = 0; start < items.length; start += 20) {
      final end = math.min(start + 20, items.length);
      final batch = items.sublist(start, end);
      final payload = <String, dynamic>{
        'sources': [
          {'lat': origin.latitude, 'lon': origin.longitude},
        ],
        'targets': batch
            .map((item) => {'lat': item.latitude, 'lon': item.longitude})
            .toList(),
        'costing': 'auto',
        'units': 'km',
        'costing_options': {
          'auto': {
            'use_highways': 0.8,
            'use_tracks': 0,
            'use_living_streets': 0,
            'exclude_unpaved': true,
            'use_tolls': 0.5,
          },
        },
      };

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      try {
        final uri = Uri.parse(
          _valhallaBase +
              '/sources_to_targets?json=' +
              Uri.encodeQueryComponent(jsonEncode(payload)),
        );
        final request = await client.getUrl(uri);
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        request.headers.set('X-Client-Id', 'turnopronto.com.br');
        final response = await request.close().timeout(
              const Duration(seconds: 14),
            );
        if (response.statusCode != 200) continue;
        final raw = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        final matrix = decoded['sources_to_targets'];

        if (matrix is Map) {
          final distances = matrix['distances'];
          if (distances is List &&
              distances.isNotEmpty &&
              distances.first is List) {
            final row = distances.first as List;
            for (var i = 0; i < row.length && i < batch.length; i++) {
              final km = double.tryParse(row[i]?.toString() ?? '');
              if (km != null && km >= 0) result[batch[i].index] = km;
            }
            continue;
          }
        }

        if (matrix is List && matrix.isNotEmpty && matrix.first is List) {
          final row = matrix.first as List;
          for (var i = 0; i < row.length && i < batch.length; i++) {
            final entry = row[i];
            if (entry is Map) {
              final km = double.tryParse(entry['distance']?.toString() ?? '');
              if (km != null && km >= 0) result[batch[i].index] = km;
            }
          }
        }
      } catch (_) {
        // Fallback OSRM logo abaixo.
      } finally {
        client.close(force: true);
      }
    }

    return result;
  }

  Future<Map<int, double>> _osrmDistances(
    _Origin origin,
    List<_ResolvedJob> items,
  ) async {
    final result = <int, double>{};
    if (items.isEmpty) return result;

    for (var start = 0; start < items.length; start += 20) {
      final end = math.min(start + 20, items.length);
      final batch = items.sublist(start, end);
      final coordinates = <String>[
        origin.longitude.toString() + ',' + origin.latitude.toString(),
        ...batch.map(
          (item) => item.longitude.toString() + ',' + item.latitude.toString(),
        ),
      ].join(';');
      final destinations =
          List.generate(batch.length, (index) => (index + 1).toString())
              .join(';');

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      try {
        final uri = Uri.parse(
          _osrmBase +
              '/table/v1/driving/' +
              coordinates +
              '?sources=0&destinations=' +
              destinations +
              '&annotations=distance',
        );
        final request = await client.getUrl(uri);
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        final response = await request.close().timeout(
              const Duration(seconds: 14),
            );
        if (response.statusCode != 200) continue;
        final raw = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        final distances = decoded['distances'];
        if (distances is! List ||
            distances.isEmpty ||
            distances.first is! List) {
          continue;
        }
        final row = distances.first as List;
        for (var i = 0; i < row.length && i < batch.length; i++) {
          final meters = double.tryParse(row[i]?.toString() ?? '');
          if (meters != null && meters >= 0) {
            result[batch[i].index] = meters / 1000;
          }
        }
      } catch (_) {
        // A tela continua com estimativa em linha reta.
      } finally {
        client.close(force: true);
      }
    }

    return result;
  }

  double _haversine(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthKm = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _rad(double degrees) => degrees * math.pi / 180;
}

class _Origin {
  const _Origin({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.manual,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final bool manual;
}

class _ResolvedJob {
  const _ResolvedJob({
    required this.index,
    required this.job,
    required this.latitude,
    required this.longitude,
  });

  final int index;
  final Job job;
  final double latitude;
  final double longitude;
}
