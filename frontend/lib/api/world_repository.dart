import 'package:dio/dio.dart';
import '../core/math/iso_math.dart';
import '../state/tile_models.dart';

/// Standard API exceptions mapped from HTTP & OpenAPI status codes.
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (code: $statusCode)';
}

class NetworkException extends ApiException {
  NetworkException(super.message, [super.statusCode]);
}

class ActionConflictException extends ApiException {
  ActionConflictException(super.message, [super.statusCode]);
}

/// Abstract contract for World API integration.
abstract class IWorldRepository {
  Future<Map<GridCoord, TileState>> fetchWorldMap();
  Future<TileState> submitTileAction({
    required GridCoord target,
    required String actionType,
    required Map<String, dynamic> parameters,
  });
  Future<void> endTurn(int currentTurn);
}

/// WorldRepository implementing network resilience, retry policies, and DTO mapping.
class WorldRepository implements IWorldRepository {
  final Dio _dio;

  WorldRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.strategy.game/v1',
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) {
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error: NetworkException('Connection to game server timed out.'),
              ),
            );
          } else if (error.response?.statusCode == 409) {
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error: ActionConflictException('Tile state changed or action invalidated by server.'),
              ),
            );
          }
          return handler.next(error);
        },
      ),
    );
  }

  @override
  Future<Map<GridCoord, TileState>> fetchWorldMap() async {
    try {
      final response = await _dio.get('/world/tiles');
      final data = response.data as Map<String, dynamic>;
      final tilesList = data['tiles'] as List<dynamic>;
      final map = <GridCoord, TileState>{};

      for (final raw in tilesList) {
        final t = raw as Map<String, dynamic>;
        final coordMap = t['coord'] as Map<String, dynamic>;
        final coord = GridCoord(coordMap['x'] as int, coordMap['y'] as int);
        final yieldsMap = t['yields'] as Map<String, dynamic>;

        TileEntity? entity;
        if (t['entity'] != null) {
          final e = t['entity'] as Map<String, dynamic>;
          entity = TileEntity(
            id: e['id'] as String,
            name: e['name'] as String,
            type: e['type'] as String,
            ownerFaction: e['owner_faction'] as String? ?? 'Player 1',
          );
        }

        map[coord] = TileState(
          coord: coord,
          type: TileType.values.byName(t['type'] as String),
          yields: ResourceYield(
            food: yieldsMap['food'] as int? ?? 0,
            production: yieldsMap['production'] as int? ?? 0,
            gold: yieldsMap['gold'] as int? ?? 0,
            science: yieldsMap['science'] as int? ?? 0,
          ),
          entity: entity,
          territoryOwner: t['territory_owner'] as String?,
        );
      }
      return map;
    } on DioException catch (e) {
      throw NetworkException(e.message ?? 'Failed to fetch world map from backend');
    }
  }

  @override
  Future<TileState> submitTileAction({
    required GridCoord target,
    required String actionType,
    required Map<String, dynamic> parameters,
  }) async {
    try {
      final response = await _dio.post(
        '/actions',
        data: {
          'action_type': actionType,
          'target_x': target.x,
          'target_y': target.y,
          'parameters': parameters,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final yieldsMap = data['yields'] as Map<String, dynamic>;

      TileEntity? entity;
      if (data['entity'] != null) {
        final e = data['entity'] as Map<String, dynamic>;
        entity = TileEntity(
          id: e['id'] as String,
          name: e['name'] as String,
          type: e['type'] as String,
          ownerFaction: e['owner_faction'] as String? ?? 'Player 1',
        );
      }

      return TileState(
        coord: target,
        type: TileType.values.byName(data['type'] as String? ?? 'plains'),
        yields: ResourceYield(
          food: yieldsMap['food'] as int? ?? 0,
          production: yieldsMap['production'] as int? ?? 0,
          gold: yieldsMap['gold'] as int? ?? 0,
          science: yieldsMap['science'] as int? ?? 0,
        ),
        entity: entity,
        territoryOwner: data['territory_owner'] as String?,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error!;
      }
      throw NetworkException(e.message ?? 'Unknown network failure');
    }
  }

  @override
  Future<void> endTurn(int currentTurn) async {
    await _dio.post(
      '/turns/end',
      data: {'turn': currentTurn},
    );
  }
}
