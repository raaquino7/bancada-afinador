import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    AudioSessionSetup.configure()
    // Uma ligação ou outro app pode desativar a sessão; ao voltar, ela é reativada.
    NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { _ in AudioSessionSetup.activate() }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

/// Uma sessão de áudio só, do app inteiro, que serve para gravar e tocar.
///
/// Sem isso, o plugin de microfone (record) troca a categoria ao gravar e a
/// saída de som (flutter_soloud) fica com a categoria que encontrar. Com uma
/// categoria fixa, alternar afinador, metrônomo e nota de referência não
/// muda nada no áudio do aparelho.
///
/// - playAndRecord: grava e toca ao mesmo tempo, e o som sai mesmo com a
///   chave de silencioso ligada (metrônomo precisa tocar no modo silencioso).
/// - defaultToSpeaker: sem isso, playAndRecord toca pelo alto-falante de
///   ligação, baixinho.
/// - allowBluetoothA2DP: o som pode ir para fones Bluetooth; o microfone
///   continua sendo o do aparelho, que ouve melhor o instrumento.
/// - mixWithOthers: abrir o app não interrompe a música de outro app.
/// - 48 kHz: a taxa nativa dos iPhones; o microfone grava nela, então a
///   taxa do hardware não muda ao ligar o microfone.
enum AudioSessionSetup {
  static func configure() {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(
        .playAndRecord,
        mode: .default,
        options: [.defaultToSpeaker, .allowBluetoothA2DP, .mixWithOthers]
      )
      try session.setPreferredSampleRate(48000)
    } catch {
      NSLog("Afinador: não foi possível configurar a sessão de áudio: \(error)")
    }
    activate()
  }

  static func activate() {
    do {
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      NSLog("Afinador: não foi possível ativar a sessão de áudio: \(error)")
    }
  }
}
