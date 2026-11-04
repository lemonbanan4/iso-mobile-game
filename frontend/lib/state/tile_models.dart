import '../core/math/iso_math.dart';

enum TileType {
  plains,
  forest,
  mountain,
  water,
  hills,
  desert;

  String get displayName {
    switch (this) {
      case TileType.plains:
        return 'Fertile Plains';
      case TileType.forest:
        return 'Dense Forest';
      case TileType.mountain:
        return 'Rocky Peaks';
      case TileType.water:
        return 'Deep Ocean';
      case TileType.hills:
        return 'Rolling Hills';
      case TileType.desert:
        return 'Arid Sands';
    }
  }

  int get movementCost {
    switch (this) {
      case TileType.plains:
        return 1;
      case TileType.forest:
      case TileType.hills:
        return 2;
      case TileType.desert:
        return 2;
      case TileType.mountain:
      case TileType.water:
        return 99; // Impassable
    }
  }
}

class ResourceYield {
  final int food;
  final int production;
  final int gold;
  final int science;

  const ResourceYield({
    this.food = 0,
    this.production = 0,
    this.gold = 0,
    this.science = 0,
  });

  static ResourceYield forTileType(TileType type) {
    switch (type) {
      case TileType.plains:
        return const ResourceYield(food: 2, gold: 1);
      case TileType.forest:
        return const ResourceYield(food: 1, production: 2);
      case TileType.mountain:
        return const ResourceYield(production: 3, science: 1);
      case TileType.water:
        return const ResourceYield(food: 1, gold: 2);
      case TileType.hills:
        return const ResourceYield(production: 2, gold: 1);
      case TileType.desert:
        return const ResourceYield(gold: 1);
    }
  }

  factory ResourceYield.fromJson(Map<String, dynamic> json) {
    return ResourceYield(
      food: json['food'] as int? ?? 0,
      production: json['production'] as int? ?? 0,
      gold: json['gold'] as int? ?? 0,
      science: json['science'] as int? ?? 0,
    );
  }
}

class TileEntity {
  final String id;
  final String name;
  final String type; // 'city', 'scout', 'warrior', 'mine', 'farm'
  final String ownerFaction;
  final int health;
  final int maxHealth;
  final int? readyAt;

  const TileEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerFaction,
    this.health = 100,
    this.maxHealth = 100,
    this.readyAt,
  });

  factory TileEntity.fromJson(Map<String, dynamic> json) {
    return TileEntity(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      ownerFaction: json['owner_faction'] as String? ?? '',
      health: json['health'] as int? ?? 100,
      maxHealth: json['max_health'] as int? ?? 100,
      readyAt:
          json['ready_at']
              as int?, // map the python snake_case to Dart camelCase
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'owner_faction': ownerFaction,
    'health': health,
    'max_health': maxHealth,
    'ready_at': readyAt,
  };
}

class TileState {
  final GridCoord coord;
  final TileType type;
  final ResourceYield yields;
  final TileEntity? entity;
  final bool isExplored;
  final bool isVisible;
  final String? territoryOwner;
  final TileEntity? unit;

  const TileState({
    required this.coord,
    required this.type,
    required this.yields,
    this.entity,
    this.isExplored = true,
    this.isVisible = true,
    this.territoryOwner,
    this.unit,
  });

  TileState copyWith({
    GridCoord? coord,
    TileType? type,
    ResourceYield? yields,
    TileEntity? entity,
    TileEntity? unit,
    bool clearUnit = false,
    bool? isExplored,
    bool? isVisible,
    String? territoryOwner,
  }) {
    return TileState(
      coord: coord ?? this.coord,
      type: type ?? this.type,
      yields: yields ?? this.yields,
      entity: entity ?? this.entity,
      unit: clearUnit ? null : (unit ?? this.unit),
      isExplored: isExplored ?? this.isExplored,
      isVisible: isVisible ?? this.isVisible,
      territoryOwner: territoryOwner ?? this.territoryOwner,
    );
  }

  factory TileState.fromJson(Map<String, dynamic> json) {
    final coordJson = json['coord'] as Map<String, dynamic>;

    return TileState(
      // Read x and y directly to create the GridCoord
      coord: GridCoord(coordJson['x'] as int, coordJson['y'] as int),
      type: TileType.values.firstWhere(
        (t) => t.name.toLowerCase() == (json['type'] as String).toLowerCase(),
        orElse: () => TileType.plains,
      ),
      yields: ResourceYield.fromJson(json['yields'] as Map<String, dynamic>),
      entity: json['entity'] != null
          ? TileEntity.fromJson(json['entity'] as Map<String, dynamic>)
          : null,
      unit: json['unit'] != null
          ? TileEntity.fromJson(json['unit'] as Map<String, dynamic>)
          : null,
      isExplored: json['is_explored'] as bool? ?? true,
      isVisible: json['is_visible'] as bool? ?? true,
      territoryOwner: json['territory_owner'] as String?,
    );
  }
}
