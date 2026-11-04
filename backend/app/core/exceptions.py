class GameRuleViolation(Exception):
    """Raised when an action violates game rules (e.g. invalid target, impassable terrain)."""
    def __init__(self, message: str):
        self.message = message
        super().__init__(self.message)

class InsufficientResourcesError(Exception):
    """Raised when player does not have enough gold/production/food to perform action."""
    def __init__(self, message: str, required: dict, available: dict):
        self.message = message
        self.required = required
        self.available = available
        super().__init__(self.message)

class TileConflictError(Exception):
    """Raised when tile is already occupied or in conflict (HTTP 409)."""
    def __init__(self, message: str):
        self.message = message
        super().__init__(self.message)

class TileNotFoundError(Exception):
    """Raised when requested tile coordinates are out of map bounds."""
    def __init__(self, x: int, y: int):
        self.message = f"Tile at ({x}, {y}) is outside valid world bounds."
        super().__init__(self.message)
