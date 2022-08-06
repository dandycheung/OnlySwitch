//
//  OnlySwitchApp.swift
//  OnlySwitch
//
//  Created by Jacklandrin on 2021/11/29.
//

import SwiftUI
import Cocoa
import KeyboardShortcuts

@main
struct OnlySwitchApp: App {
    let persistenceController = PersistenceController.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var preferencesvm = PreferencesPublisher.shared
    @State var preferences = PreferencesPublisher.shared.preferences
    var body: some Scene {
        WindowGroup("SettingsWindow"){
            SettingView()
                .frame(width: Layout.settingWindowWidth, height: Layout.settingWindowHeight)
                .task {
                    CustomizeVM.shared.allSwitches.forEach{ item in
                        KeyboardShortcuts.onKeyDown(for: item.keyboardShortcutName) {
                            item.doSwitch()
                        }
                    }
                    
                    ShortcutsSettingVM.shared.shortcutsList.forEach{ item in
                        KeyboardShortcuts.onKeyDown(for: item.keyboardShortcutName) {
                            item.doShortcuts()
                        }
                    }
                }
            
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
        .commands{
            CommandMenu("Switches Availability") {
                Button(action: {
                    preferencesvm.preferences.radioEnable = !preferences.radioEnable
                    if preferences.radioEnable {
                        PlayerManager.shared.player.setupRemoteCommandCenter()
                    } else {
                        RadioStationSwitch.shared.playerItem.isPlaying = false
                        PlayerManager.shared.player.clearCommandCenter()
                    }
                }, label: {
                    if preferencesvm.preferences.radioEnable {
                        Text("Disable Radio Player")
                    } else {
                        Text("Enable Radio Player")
                    }
                })
                Button(action: {
                    preferencesvm.preferences.menubarCollaspable = !preferences.menubarCollaspable
                }, label: {
                    if preferencesvm.preferences.menubarCollaspable {
                        Text("Disable Hide Menu Bar Icons")
                    } else {
                        Text("Enale Hide Menu Bar Icons")
                    }
                })
            }
            CommandGroup(replacing: .newItem) {
                
            }
        }
        
    }
}

class AppDelegate:NSObject, NSApplicationDelegate {
    var statusBar: StatusBarController?
    var popover = NSPopover()
    let switchVM = SwitchListVM()
    var blManager:BluetoothDevicesManager?
    var currentAppearance:String {
        return PreferencesPublisher
            .shared
            .preferences
            .currentAppearance
    }
    var checkUpdatePresenter = GitHubPresenter()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            window.orderOut(nil)
            NSApplication.shared.setActivationPolicy(.accessory)
            NSWindow.allowsAutomaticWindowTabbing = false
        }
        let contentView = OnlySwitchListView()
            .environmentObject(switchVM)
        let apperearance = SwitchListAppearance(rawValue: currentAppearance)
        
        popover.contentSize = NSSize(width: apperearance == .single ? Layout.popoverWidth : Layout.popoverWidth * 2 - 40, height: 300)
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        statusBar = StatusBarController(popover)
        
        SwitchManager.shared.registerSwitchesShouldShow()
        
        blManager = BluetoothDevicesManager.shared
        RadioStationSwitch.shared.setDefaultRadioStations()
        Bundle.setLanguage(lang: LanguageManager.sharedManager.currentLang)
        
        checkUpdate()
        //for issue #11
        
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        
    }
    
    func applicationDidUpdate(_ notification: Notification) {
        if let event = NSApp.currentEvent {
            if event.type == .appKitDefined,
               let window = NSApp.mainWindow{
                if window.delegate == nil {
                    window.close()
                }
            }
        }
    }
    
    func checkUpdate() {
        checkUpdatePresenter.checkUpdate { result in
            switch result {
            case .success:
                let newestVersion = self.checkUpdatePresenter.latestVersion
                UserDefaults.standard.set(newestVersion, forKey: UserDefaults.Key.newestVersion)
                UserDefaults.standard.synchronize()
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }
    
    
}
