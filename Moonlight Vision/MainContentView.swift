//
//  MainContentView.swift
//  Moonlight Vision
//
//  Created by Alex Haugland on 1/22/24.
//  Copyright © 2024 Moonlight Game Streaming Project.
//


import SwiftUI

struct MainContentView: View {
    @EnvironmentObject private var viewModel: MainViewModel

    @State private var selectedHost: TemporaryHost?

    @State private var addingHost = false
    @State private var isDeletingHost = false
    @State private var hostToDelete: TemporaryHost?
    @State private var newHostIp = ""
    @State private var dimPassthrough = true
    @State private var isRefreshingDiscovery = false // State to track refresh status


    var body: some View {
        TabView {
            NavigationSplitView {
                VStack { // Wrap List and text in a VStack
                    List(viewModel.hostsWithPairState, selection: $selectedHost) { host in
                        NavigationLink(value: host) {
                            hostRow(for: host)
                        }
                    }
                    .alert("Really delete?", isPresented: $isDeletingHost) {
                        Button("Yes, delete it", role: .destructive) {
                            if let hostToDelete {
                                viewModel.removeHost(hostToDelete)
                                selectedHost = nil
                            }
                        }
                        Button("Cancel", role: .cancel) {
                            isDeletingHost = false
                            hostToDelete = nil
                        }
                    }
                    .onChange(of: viewModel.hosts) {
                        // If the hosts list changes and no host is selected,
                        // try to select the first paired host automatically.
                        if selectedHost == nil,
                           let firstHost = viewModel.hosts.first(where: { $0.pairState == .paired })
                        {
                            selectedHost = firstHost
                        }
                    }
                    .navigationTitle("Computers") // Keep simple navigation title
                    // REMOVE the VStack navigationTitle we added before

                    Button { // Make the Text a Button
                        isRefreshingDiscovery.toggle()
                        if isRefreshingDiscovery {
                            viewModel.beginRefresh()
                        } else {
                            viewModel.stopRefresh()
                        }
                    } label: {
                        Text(isRefreshingDiscovery ? "Click here to Stop network discovery, or if things are unresponsive" : "Click here to scans for Hosts") // Conditional Text
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding() // Add some bottom padding for visual spacing
                    .buttonStyle(.plain) // Remove button styling to make it look like text
                }
                .toolbar { // Keep the toolbar as is for now
                    ToolbarItem(placement: .primaryAction) {
                        Button("Add Server", systemImage: "plus") {
                            addingHost = true
                        }.alert(
                            "Enter server",
                            isPresented: $addingHost
                        ) {
                            TextField("IP or Host", text: $newHostIp)
                            Button("Add") {
                                addingHost = false
                                viewModel.manuallyDiscoverHost(hostOrIp: newHostIp)
                            }
                            Button("Cancel", role: .cancel) {
                                addingHost = false
                            }
                        }.alert(
                            "Unable to add host",
                            isPresented: $viewModel.errorAddingHost
                        ) {
                            Button("Ok", role: .cancel) {
                                viewModel.errorAddingHost = true
                            }
                        } message: {
                            Text(viewModel.addHostErrorMessage)
                        }
                    }
                }
            } detail: {
                if let selectedHost = Binding<TemporaryHost>($selectedHost) {
                    ComputerView(host: selectedHost)
                }
            }.tabItem {
                Label("Computers", systemImage: "desktopcomputer")
            }
            .task {
                viewModel.loadSavedHosts()
            }
            .onAppear {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(viewModel.beginRefresh),
                    name: UIApplication.didBecomeActiveNotification,
                    object: nil
                )
                //if !isRefreshingDiscovery { // Only begin refresh if not already toggled on
                //    viewModel.beginRefresh()
                //}
            }.onDisappear {
                //if !isRefreshingDiscovery { // Only stop refresh if not toggled on and still running
                    viewModel.stopRefresh()
                //}
                NotificationCenter.default.removeObserver(self)
            }

            SettingsView(settings: $viewModel.streamSettings).tabItem {
                Label("Settings", systemImage: "gear")
            }

            UpdatesView().tabItem {
                Label("Changelog", systemImage: "info.circle.fill")
            }

        }
    }

    private func hostRow(for host: TemporaryHost) -> some View {
        VStack {
            Label(host.name,
                  systemImage: host.pairState == .paired ?
                      "desktopcomputer" : "lock.desktopcomputer")
                .foregroundColor(.primary)
        }.contextMenu {
            Button {
                viewModel.wakeHost(host)
            } label: {
                Label("Wake PC", systemImage: "sun.horizon")
            }
            Button(role: .destructive) {
                isDeletingHost = true
                hostToDelete = host
            } label: {
                Label("Delete PC", systemImage: "trash")
            }
        }
    }
}

#Preview {
    MainContentView().environmentObject(MainViewModel())
}
