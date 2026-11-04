import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/game_theme.dart';
import 'game/strategy_game.dart';
import 'state/game_state_provider.dart';
import 'ui/hud/event_log_ticker.dart';
import 'ui/hud/resource_dashboard.dart';
import 'ui/hud/tile_inspector_panel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Immersive edge-to-edge layout for mobile
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: StrategyApp()));
}

class StrategyApp extends StatelessWidget {
  const StrategyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iso Syndicate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: GameTheme.backgroundDark,
        textTheme: GoogleFonts.rajdhaniTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ).apply(
          bodyColor: GameTheme.textPrimary,
          displayColor: GameTheme.textPrimary,
        ),
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final StrategyGame _game;

  @override
  void initState() {
    super.initState();
    // Instantiate Flame game decoupled from widget lifecycle
    _game = StrategyGame(
      onTileSelected: (coord) {
        ref.read(gameStateProvider.notifier).selectTile(coord);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to reactive state changes and forward them to the Flame game instance
    ref.listen<GameState>(gameStateProvider, (previous, next) {
      if (previous?.tiles != next.tiles) {
        _game.updateWorldTiles(next.tiles);
      }
      if (previous?.selectedCoord != next.selectedCoord) {
        _game.setSelectedCoord(next.selectedCoord);
      }
    });
    ref.listen<GameState>(gameStateProvider, (previous, next) {
      if (previous?.gachaPull == null && next.gachaPull != null) {
        final pull = next.gachaPull!;
        final rarity = pull['rarity'] as String? ?? 'Common';

        // Determine the glow color based on server rarity
        Color glowColor = Colors.grey;
        if (rarity == 'Rare') glowColor = Colors.blue;
        if (rarity == 'Epic') glowColor = Colors.purple;
        if (rarity == 'Legendary') glowColor = Colors.orangeAccent;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: glowColor, width: 2),
            ),
            title: Text(
              '✨ $rarity Summon! ✨',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: glowColor,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.diamond_rounded, size: 80, color: glowColor),
                const SizedBox(height: 16),
                Text(
                  pull['name'] ?? 'Unknown Hero',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'HP: ${pull['health']}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: glowColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref.read(gameStateProvider.notifier).clearGachaPull();
                  },
                  child: const Text('Claim Hero'),
                ),
              ),
            ],
          ),
        );
      }
    });

    final gameState = ref.watch(gameStateProvider);

    return Scaffold(
      body: Stack(
        children: [
          // 1. GAME ENGINE CANVAS LAYER (Pure Flame isometric grid)
          Positioned.fill(child: GameWidget(game: _game)),

          // Soft cyberpunk vignette over the canvas (HUD chrome only)
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: GameTheme.voidGlow),
              child: const SizedBox.expand(),
            ),
          ),

          // 2. TOP HUD: syndicate resource ledger
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ResourceDashboard(),
          ),

          // 3. EVENT LOG TICKER (randomized syndicate encounters)
          const Positioned(
            top: 88,
            left: 0,
            right: 0,
            child: EventLogTicker(),
          ),

          // 4. BOTTOM HUD: modular cell / district placement inspector
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: TileInspectorPanel(),
          ),

          // 5. SERVER SYNC / TRANSACTION SPINNER OVERLAY
          if (gameState.isSyncingWithServer)
            Positioned(
              top: 140,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: GameTheme.accentNeon.withValues(alpha: 0.5),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          GameTheme.accentNeon,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'UPLINK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: GameTheme.accentNeon,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // 6. VICTORY OVERLAY
          if (gameState.isVictory)
            Positioned.fill(
              child: Container(
                color: const Color(0xFF070A12).withValues(alpha: 0.95),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        size: 100,
                        color: Colors.amber,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'DOMINANCE',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Rival crews erased. The syndicate owns the grid.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        onPressed: () {},
                        child: const Text(
                          'REOPEN THE NET',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 7. DEFEAT OVERLAY
          if (gameState.isDefeat)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.95),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 100,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'BUSTED',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your capital cell fell. The syndicate is dust.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
