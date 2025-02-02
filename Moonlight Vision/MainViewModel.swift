//
//  MainViewModel.swift
//  Moonlight Vision
//
//  Created by Alex Haugland on 1/22/24.
//  Copyright © 2024 Moonlight Game Streaming Project. All rights reserved.
//

import Foundation
import OrderedCollections
import VideoToolbox
import AVFoundation

@MainActor
class MainViewModel: NSObject, ObservableObject, DiscoveryCallback, PairCallback, AppAssetCallback {
    @Published var hosts: [TemporaryHost] = []

    @Published var pairingInProgress = false
    @Published var currentPin = ""

    @Published var errorAddingHost = false
    @Published var addHostErrorMessage = ""

    @Published var currentStreamConfig = StreamConfiguration()
    @Published var activelyStreaming = false
    @Published var streamSettings: TemporarySettings

    @Published var volumeSliderValue: Float = 1.0

    @Published var dimPassthrough = true
    @Published var vol: Float = 127
    @Published var mute: Bool = false

    private var dataManager: DataManager
    private var discoveryManager: DiscoveryManager? = nil
    private var appManager: AppAssetManager?
    private var boxArtCache: NSCache<TemporaryApp, UIImage>
    private var clientCert: Data
    private var uniqueId: String

    private var opQueue = OperationQueue()
    private var currentlyPairingHost: TemporaryHost?

    override init() {
        boxArtCache = NSCache<TemporaryApp, UIImage>()
        dataManager = DataManager()
        // should this be in viewDidLoad and not init?
        CryptoManager.generateKeyPairUsingSSL()
        clientCert = CryptoManager.readCertFromFile()
        uniqueId = IdManager.getUniqueId()
        streamSettings = dataManager.getSettings()

        super.init()
        appManager = AppAssetManager(callback: self)
        discoveryManager = DiscoveryManager(hosts: hosts, andCallback: self)

        // Start discovery immediately when MainViewModel is initialized (on app startup)
    }

    func compareHostNamesIgnoringLocal(_ name1: String, _ name2: String) -> Bool {
        let name1WithoutLocal = name1.hasSuffix(".local") ? String(name1.dropSuffix(".local")) : name1
        let name2WithoutLocal = name2.hasSuffix(".local") ? String(name2.dropSuffix(".local")) : name2
        return name1WithoutLocal.caseInsensitiveCompare(name2WithoutLocal) == .orderedSame
    }


    func setHosts(newHosts: [TemporaryHost]) {
        print("setHosts - START - Current hosts count: \(hosts.count), New hosts count: \(newHosts.count)")
        print("setHosts - Old hosts before processing: \(hosts.map { ($0.name, $0.uuid) })")

        // 1. Deduplicate newHosts based on UUID (keep last occurrence)
        var deduplicatedNewHosts: [TemporaryHost] = []
        var seenUUIDs = Set<String>() // Set to track UUIDs

        print("setHosts - Starting UUID-based deduplication of newHosts...")
        for host in newHosts.reversed() {
            let uuid = host.uuid // Directly access non-optional uuid
            if !seenUUIDs.contains(uuid) {
                deduplicatedNewHosts.append(host)
                seenUUIDs.insert(uuid)
                print("setHosts - Deduplication: Keeping host (UUID: \(uuid)): \(host.name)")
            } else {
                print("setHosts - Deduplication: Duplicate host UUID (\(uuid)) found for host \(host.name). Discarding.")
            }
        }
        deduplicatedNewHosts.reverse() // Restore original order
        print("setHosts - UUID-based deduplication of newHosts complete. Deduplicated count: \(deduplicatedNewHosts.count), Hosts: \(deduplicatedNewHosts.map { ($0.name, $0.uuid) })")


        // 2. Merge deduplicatedNewHosts with existing hosts based on UUID (replace or append)
        var mergedHosts: [TemporaryHost] = []
        mergedHosts.append(contentsOf: hosts) // Start with existing hosts
        print("setHosts - Initial mergedHosts (copy of existing hosts): \(mergedHosts.map { ($0.name, $0.uuid) })")

        print("setHosts - Starting UUID-based merge process...")
        for newHost in deduplicatedNewHosts {
            let newHostUUID = newHost.uuid // Directly access non-optional uuid

            if let existingIndex = mergedHosts.firstIndex(where: { existingHost in
                let existingHostUUID = existingHost.uuid // Directly access non-optional uuid
                return existingHostUUID == newHostUUID
            }) {
                print("setHosts - Merge: Host with same UUID (\(newHostUUID)) found in mergedHosts at index \(existingIndex). Replacing with: \(newHost.name)")
                mergedHosts[existingIndex] = newHost // Replace existing host
            } else {
                print("setHosts - Merge: New host UUID (\(newHostUUID)) not found in mergedHosts. Appending: \(newHost.name)")
                mergedHosts.append(newHost) // Append new host
            }
        }
        print("setHosts - UUID-based merge process complete. Final mergedHosts count: \(mergedHosts.count), Hosts: \(mergedHosts.map { ($0.name, $0.uuid) })")


        // 3. Update the hosts array
        hosts.removeAll() // Clear the old hosts array
        hosts.append(contentsOf: mergedHosts) // Set hosts to the merged and deduplicated list
        print("setHosts - hosts array updated with mergedHosts. Final hosts count: \(hosts.count), Hosts: \(hosts.map { ($0.name, $0.uuid) })")
        print("setHosts - END")
    }
    
    func addHost(newHost: TemporaryHost) {
        print("addHost - START - Attempting to add host: \(newHost.name), UUID: \(newHost.uuid), Address: \(newHost.address), Current hosts count: \(hosts.count)")
        // **First, check for object identity.** (Keep this check)
        if hosts.contains(where: { $0 === newHost }) {
            print("addHost - Host already exists in array by object identity: \(newHost.name), UUID: \(newHost.uuid). NOT appending.")
            print("addHost - END - Host not added (identity)")
            return // Do not add if it's the exact same object
        }

        print("addHost - No identity match. Proceeding to append (after delay).")
        print("addHost - Started 5-second delay before appending host: \(newHost.name), UUID: \(newHost.uuid)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            print("addHost - Delay finished, now appending host: \(newHost.name), UUID: \(newHost.uuid)")
            self.hosts.append(newHost)
            print("addHost - Host appended. Current hosts array: \(self.hosts.map { ($0.name, $0.uuid) })")
            print("addHost - END - Host appended")
        }
        print("addHost - END - Delay started") // Log end even when delay is started
    }

    func removeHost(_ hostToRemove: TemporaryHost) { // Renamed parameter for clarity
        print("removeHost - START - Attempting to remove host: \(hostToRemove.name), UUID: \(hostToRemove.uuid), Current hosts count: \(hosts.count)")
        if hosts.contains(hostToRemove) {
            print("removeHost - Host found in hosts array. Proceeding to remove.")
            //print("Removing host: \(hostToRemove.name) (UUID: \(hostToRemove.uuid))") // Log before removal - already logged above
            discoveryManager?.removeHost(fromDiscovery: hostToRemove)
            dataManager.remove(hostToRemove)
            print("removeHost - Before removeAll(where), hosts array: \(hosts.map { ($0.name, $0.uuid) })")
            hosts.removeAll(where: { $0 == hostToRemove })
            print("removeHost - Host removed. Current hosts array: \(hosts.map { ($0.name, $0.uuid) })")
            //print("Host removed successfully: \(hostToRemove.name)") // Log after removal - already logged above
            print("removeHost - END - Host removed successfully")
        } else {
            print("removeHost - Warning: Attempted to remove host \(hostToRemove.name) (UUID: \(hostToRemove.uuid)) but it was NOT found in the hosts list.")
            print("removeHost - Current hosts array: \(hosts.map { ($0.name, $0.uuid) })")
            // Log a warning if the host is not found.  This should ideally NOT happen
            // if the UI is correctly reflecting the current state of `viewModel.hosts`.
            print("removeHost - END - Host not found, not removed")
        }
    }


    func wakeHost(_ host: TemporaryHost) {
        WakeOnLanManager.wake(host)
    }

    // MARK: App Icons

    nonisolated func receivedAsset(for app: TemporaryApp!) {
        // pass
    }

    // MARK: Pairing

    func manuallyDiscoverHost(hostOrIp: String) {
        discoveryManager?.discoverHost(hostOrIp, withCallback: hostMaybeFound)
    }

    nonisolated func hostMaybeFound(host: TemporaryHost?, error: String?) {
        Task { @MainActor in
            if let host {
                print("hostMaybeFound - Discovered host: \(host), name: \(host.name )") // Log name here
                self.addHost(newHost: host)
                await self.updateHost(host: host)
            } else {
                print("hostMaybeFound - Error discovering host: \(error ?? "Unknown error")")
                self.errorAddingHost = true
                self.addHostErrorMessage = error ?? "Unknown Error"
            }
        }
    }

    func tryPairHost(_ host: TemporaryHost) {
        discoveryManager?.stopDiscoveryBlocking()
        let httpManager = HttpManager(host: host)
        // do we need to retain this? probably?
        let pairManager = PairManager(manager: httpManager, clientCert: clientCert, callback: self)
        opQueue.addOperation(pairManager!)
        currentlyPairingHost = host
        print("trying to pair")
    }

    nonisolated func startPairing(_ PIN: String!) {
        Task { @MainActor in
            pairingInProgress = true
            currentPin = PIN
        }
        print("pairing started")
    }

    nonisolated func pairSuccessful(_ serverCert: Data!) {
        Task { @MainActor in
            currentlyPairingHost?.serverCert = serverCert
        }
        endPairing()
    }

    nonisolated func pairFailed(_ message: String!) {
        endPairing()
    }

    nonisolated func alreadyPaired() {
        endPairing()
    }

    nonisolated func endPairing() {
        Task { @MainActor in
            pairingInProgress = false
            discoveryManager?.startDiscovery() // keep discovery running after pairing?
            if let currentlyPairingHost { await updateHost(host: currentlyPairingHost) }
            currentlyPairingHost = nil
        }
    }

    func updateHost(host: TemporaryHost) async {
        print("updateHost - Starting for host: \(host), initial name: \(host.name)") // Log initial name

        // 1. Check if a host with the same name (or same name without .local) already exists in dataManager
        if let savedHosts = dataManager.getHosts() as? [TemporaryHost] {
            for savedHost in savedHosts {
                if compareHostNamesIgnoringLocal(host.name, savedHost.name) {
                    print("updateHost - Host with the same name already saved, skipping update: \(host.name)")
                    //stopRefresh()
                    return // Skip dataManager.update if host with same name is already saved
                }
            }
        }


        Task {
            let httpManager = HttpManager(host: host)
            discoveryManager?.pauseDiscovery(for: host)
            host.updatePending = true
            let serverInfoResponse = ServerInfoResponse()
            let request = HttpRequest(for: serverInfoResponse, with: httpManager?.newServerInfoRequest(false), fallbackError: 401, fallbackRequest: httpManager?.newHttpServerInfoRequest())
            print("Executing request for host: \(host)")
            httpManager?.executeRequestSynchronously(request)
            discoveryManager?.resumeDiscovery(for: host)

            host.updatePending = false
            if serverInfoResponse.isStatusOk() {
                print("updateHost - Server info OK for host: \(host), before populate name: \(host.name)") // Log before populate
                serverInfoResponse.populateHost(host)
                print("updateHost - Server info OK for host: \(host), after populate name: \(host.name)") // Log after populate
                dataManager.update(host)
                //stopRefresh()
            } else {
                print("updateHost - Server info FAILED for host: \(host), before default name: \(host.name)")
                // Set a default name if server info fetch fails
                if host.name.isEmpty {
                    if let hostAddress = host.address { // Use address if available
                        host.name = "Host at \(hostAddress)"
                    } else {
                        host.name = "Discovered Host (No Info)" // Fallback if no address either
                    }
                }
                print("updateHost - Server info FAILED for host: \(host), after default name: \(host.name)")
                //stopRefresh()
            }
            // Update the host in DataManager even if server info fetch failed (with default name)
        }
    }


    func refreshAppsFor(host: TemporaryHost) {
        // possibly put loading stuff somewhere?
        discoveryManager?.pauseDiscovery(for: host)
        let appListResponse = ConnectionHelper.getAppList(for: host)
        discoveryManager?.resumeDiscovery(for: host)
        if appListResponse?.isStatusOk() == true {
            let serverApps = (appListResponse!.getAppList() as! Set<TemporaryApp>)

            var newAppList = OrderedSet<TemporaryApp>()
            // Only new apps we have received are valid, but keep the old object and state if it exists.
            for serverApp in serverApps {
                var matchFound = false
                for oldApp in host.appList {
                    if serverApp.id == oldApp.id {
                        oldApp.name = serverApp.name
                        oldApp.hdrSupported = serverApp.hdrSupported
                        oldApp.setHost(host)
                        // Ignore hidden, we want to respect the saved state.
                        matchFound = true
                        newAppList.append(oldApp)
                        break
                    }
                }
                if !matchFound {
                    serverApp.setHost(host)
                    newAppList.append(serverApp)
                }
            }

            let removedApps = host.appList.subtracting(newAppList)
            let database = DataManager()
            for removedApp in removedApps {
                database.remove(removedApp)
            }

            database.updateApps(forExisting: host)

            // self.updateHostShortcuts
            host.appList = newAppList
        }
    }

    // MARK: Host discovery

    func loadSavedHosts() {
        print("loadSavedHosts - Start loading...") // Add log at start

        guard let savedHosts = dataManager.getHosts() as? [TemporaryHost] else {
            print("loadSavedHosts - Unable to fetch saved hosts from DataManager.")
            return // Exit if no saved hosts
        }

        print("loadSavedHosts - Fetched saved hosts from DataManager: \(savedHosts)")

        setHosts(newHosts: savedHosts) // **Crucially use setHosts to replace the array**

        print("loadSavedHosts - Hosts array set to loaded hosts. Current hosts array: \(hosts)") // Log current hosts after setting

        for host in hosts { // Update active addresses AFTER setting the hosts array
            if host.activeAddress == nil {
                host.activeAddress = host.localAddress
            }
            if host.activeAddress == nil {
                host.activeAddress = host.externalAddress
            }
            if host.activeAddress == nil {
                host.activeAddress = host.address
            }
            if host.activeAddress == nil {
                host.activeAddress = host.ipv6Address
            }
        }
        //stopRefresh()
        print("loadSavedHosts - Finished loading and updating active addresses.") // Log at the end
    }
    
    nonisolated func updateAllHosts(_ newHosts: [Any]!) {
        print("updateAllHosts - CALLBACK RECEIVED - New hosts array (Any) count: \(newHosts?.count ?? 0)")
        if let newHosts = newHosts as? [TemporaryHost] {
            print("updateAllHosts - Type cast successful to [TemporaryHost], count: \(newHosts.count)")
            Task { @MainActor in
                print("updateAllHosts - Dispatching to MainActor to call setHosts")
                await setHosts(newHosts: newHosts)
                print("updateAllHosts - setHosts call completed")
            }
        } else {
            print("updateAllHosts - Type cast FAILED to [TemporaryHost] or newHosts is nil.")
        }
        print("updateAllHosts - CALLBACK END")
    }


    @objc func beginRefresh() {
        discoveryManager?.resetDiscoveryState()
        discoveryManager?.startDiscovery()
    }

    func stopRefresh() {
        print("Stopping Scans") // Log before populate
        discoveryManager?.stopDiscovery()
    }

    // MARK: Stream Control

    func stream(app: TemporaryApp) -> StreamConfiguration? {
        let config = StreamConfiguration()

        guard let host = app.host() else {
            return nil
        }

        config.host = host.activeAddress
        config.httpsPort = host.httpsPort
        config.appID = app.id
        config.appName = app.name
        config.serverCert = host.serverCert

        config.frameRate = streamSettings.framerate

        #if os(visionOS)
        // leave framerate as is
        #else
        // clamp framerate to maximum
        #endif

        config.height = streamSettings.height
        config.width = streamSettings.width

        config.bitRate = streamSettings.bitrate
        config.optimizeGameSettings = streamSettings.optimizeGames
        config.playAudioOnPC = streamSettings.playAudioOnPC
        config.useFramePacing = streamSettings.useFramePacing
        config.swapABXYButtons = streamSettings.swapABXYButtons
        config.multiController = streamSettings.multiController
        config.gamepadMask = ControllerSupport.getConnectedGamepadMask(config)

        // 7.1, always
        config.audioConfiguration = (0x63f << 16) | (8 << 8) | 0xca

        // all of them? i guess? this forces hdr on
        config.serverCodecModeSupport = host.serverCodecModeSupport

        // figure out how to nicely import the c++ headers

        let AV1_MAIN8: Int32 = 0x1000
        let AV1_MAIN10: Int32 = 0x2000
        let H265: Int32 = 0x0100
        let H264: Int32 = 0x0001
        let H265_MAIN10: Int32 = 0x0200

        let av1_supported = VideoToolbox.VTIsHardwareDecodeSupported(kCMVideoCodecType_AV1)
        let hdr10_supported = AVPlayer.availableHDRModes.contains(AVPlayer.HDRMode.hdr10)
        switch streamSettings.preferredCodec {
        case .av1:
            if av1_supported {
                config.supportedVideoFormats |= AV1_MAIN8
            }
        case .auto:
            fallthrough
        case .hevc:
            if VideoToolbox.VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC) {
                config.supportedVideoFormats |= H265
            }
        case .h264:
            config.supportedVideoFormats |= H264
        }

        if config.width > 4096 || config.height > 4096 || streamSettings.enableHdr {
            if VideoToolbox.VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC) {
                config.supportedVideoFormats |= H265
            }

            if streamSettings.enableHdr && hdr10_supported {
                config.supportedVideoFormats |= H265_MAIN10
            }

            let av1_enabled = config.supportedVideoFormats & 0xf000 != 0
            if av1_enabled && streamSettings.enableHdr && av1_supported && hdr10_supported {
                config.supportedVideoFormats |= AV1_MAIN10
            }
        }

        currentStreamConfig = config
        activelyStreaming = true
        return currentStreamConfig
    }
}

extension String {
    func dropSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else { return self }
        return String(dropLast(suffix.count))
    }
}
