import 'package:audioplayers/audioplayers.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/owlet.dart';
import '../packages/enemy_generator.dart';

class TinyGame extends FlameGame
    with KeyboardEvents, TapDetector, HasCollisionDetection {
  late Owlet owlet; // Animations for the Owlet
  late EnemyGenerator enemyGenerator;
  late ParallaxComponent parallaxComponent; // Map
  late TextComponent scoreComponent;
  late TextComponent scoreTitle;
  late double score;
  bool isPaused = false;
  double currentSpeed = 0.3;

  static final player = FlameAudio.bgm.audioPlayer;

  TinyGame() {
    enemyGenerator = EnemyGenerator();
    scoreComponent = TextComponent();
    scoreTitle = TextComponent();
  }

  @override
  Future<void>? onLoad() async {
    owlet = await Owlet.create();

    await FlameAudio.audioCache
        .loadAll(['bgr.mp3', 'jump.wav', 'death.mp3', 'hurt.mp3']);
    player.play(AssetSource('bgr.mp3'), volume: 80);
    player.setReleaseMode(ReleaseMode.loop);

    parallaxComponent = await loadParallaxComponent(
      [
        // Parallax Forest Background
        ParallaxImageData('Background/Layer_0011_0.png'),
        ParallaxImageData('Background/Layer_0010_1.png'),
        ParallaxImageData('Background/Layer_0009_2.png'),
        ParallaxImageData('Background/Layer_0008_3.png'),
        ParallaxImageData('Background/Layer_0007_Lights.png'),
        ParallaxImageData('Background/Layer_0006_4.png'),
        ParallaxImageData('Background/Layer_0005_5.png'),
        ParallaxImageData('Background/Layer_0004_Lights.png'),
        ParallaxImageData('Background/Layer_0003_6.png'),
        ParallaxImageData('Background/Layer_0002_7.png'),
        ParallaxImageData('Background/Layer_0001_8.png'),
        ParallaxImageData('Background/Layer_0000_9.png'),
      ],
      baseVelocity: Vector2(currentSpeed, 0), // Map Move Speed
      velocityMultiplierDelta: Vector2(1.8, 1.0),
    );

    score = 0;
    scoreTitle = TextComponent(
      text: "Score",
      textRenderer: TextPaint(
          style: TextStyle(
              fontFamily: 'Audiowide', fontSize: size.y - size.y * 90 / 100)),
    );

    scoreComponent = TextComponent(
        text: score.toStringAsFixed(0),
        anchor: Anchor.topCenter,
        textRenderer: TextPaint(
            style: TextStyle(
                fontFamily: 'Audiowide',
                fontSize: size.y - size.y * 94 / 100,
                color: Colors.yellow)));

    addAll([
      parallaxComponent,
      owlet,
      owlet.dust,
      enemyGenerator,
      scoreTitle,
      scoreComponent,
    ]);

    overlays.add("Pause Button");
    overlays.add("Lives");

    onGameResize(canvasSize);
    return super.onLoad();
  }

  @override
  void update(double dt) {
    // Game Over Check
    gameOver();

    // Score Manipulation
    score += 60 * dt;
    scoreComponent.text = score.toStringAsFixed(0);

    // Smoke run / jump Animation
    if (!owlet.onGround()) {
      owlet.dust.jumpDust();
    }
    if (owlet.onGround()) {
      owlet.dust.runDust();
    }
    if (owlet.isAttacking) {
      owlet.attack();
    }

    super.update(dt);
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    // Score Title Resizing
    scoreTitle.x = (canvasSize.x - scoreComponent.width - scoreTitle.width) / 2;
    scoreTitle.y = canvasSize.y - canvasSize.y * 88 / 100;

    // Score Resizing
    scoreComponent.x = (canvasSize.x - scoreComponent.width) / 2;
    scoreComponent.y = canvasSize.y - canvasSize.y * 75 / 100;
    super.onGameResize(canvasSize);
  }

  @override
  void onTapDown(TapDownInfo info) {
    // Handle the Screen Touch Taps
    // owlet.jump();

    // Check if the click on right or left side
    var width = info.eventPosition.widget.x;
    if (width < size.length / 2) {
      owlet.jump();
    } else {
      owlet.attack();
    }
    // ----
    super.onTapDown(info);
  }

  void gameOver() async {
    if (owlet.life.value <= 0) {
      player.stop();
      enemyGenerator.removeAllEnemy();
      scoreComponent.removeFromParent();
      scoreTitle.removeFromParent();
      owlet.die();
      await Future.delayed(const Duration(milliseconds: 500));
      overlays.add('Game Over');
      pauseEngine();
    }
  }

  @override
  KeyEventResult onKeyEvent(
      RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Keyboard Space Taps
    final isSpace = keysPressed.contains(LogicalKeyboardKey.space);

    if (isSpace) {
      owlet.jump();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
