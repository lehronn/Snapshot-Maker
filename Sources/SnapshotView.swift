import SwiftUI

struct SnapshotView: View {
    let vm: VirtualMachine
    @State private var snapshots: [Snapshot] = []
    @State private var newSnapshotName: String = ""
    @State private var toast: Toast?
    @State private var showDeleteConfirmation: Snapshot?
    @State private var showRestoreConfirmation: Snapshot?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("snapshots".localized)
                .font(.headline)
            
            HStack {
                TextField("snapshot_name_placeholder".localized, text: $newSnapshotName)
                Button("create_snapshot".localized) {
                    createSnapshot()
                }
                .disabled(newSnapshotName.isEmpty)
            }
            .padding(.bottom)
            
            // Snapshots list or empty state
            if snapshots.isEmpty {
                VStack {
                    Spacer()
                    Text("no_snapshots".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                }
                .frame(minHeight: 150)
            } else {
                List {
                    ForEach(snapshots) { snap in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(snap.tag).font(.body)
                                Text("\("created_at".localized): \(snap.date)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            Button("restore_snapshot".localized) {
                                showRestoreConfirmation = snap
                            }
                            
                            Button("delete_snapshot".localized) {
                                showDeleteConfirmation = snap
                            }
                        }
                    }
                }
                .frame(minHeight: 200)
            }
        }
        .padding()
        .onAppear {
            refreshSnapshots()
        }
        .toast($toast)
        .alert(item: $showDeleteConfirmation) { snap in
            Alert(
                title: Text("delete_snapshot".localized),
                message: Text("Are you sure you want to delete snapshot '\(snap.tag)'?"),
                primaryButton: .destructive(Text("delete_snapshot".localized)) {
                    deleteSnapshot(snap)
                },
                secondaryButton: .cancel()
            )
        }
        .alert(item: $showRestoreConfirmation) { snap in
            Alert(
                title: Text("restore_snapshot".localized),
                message: Text("Are you sure you want to restore to snapshot '\(snap.tag)'? This will revert the disk to this state."),
                primaryButton: .default(Text("restore_snapshot".localized)) {
                    restoreSnapshot(snap)
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    /// Refresh the list of snapshots from QEMU
    func refreshSnapshots() {
        print("🔍 DEBUG: Refreshing snapshots for VM: \(vm.name)")
        snapshots = QemuManager.shared.listSnapshots(vm: vm)
        print("🔍 DEBUG: Found \(snapshots.count) snapshots")
        for snapshot in snapshots {
            print("  - \(snapshot.tag) (\(snapshot.date))")
        }
    }
    
    /// Create a new snapshot with the specified name
    func createSnapshot() {
        print("📸 DEBUG: Creating snapshot '\(newSnapshotName)' for \(vm.name)")
        do {
            try QemuManager.shared.createSnapshot(vm: vm, name: newSnapshotName)
            print("✅ DEBUG: Snapshot created successfully")
            newSnapshotName = ""
            refreshSnapshots()
            toast = Toast(message: "snapshot_created_success".localized, type: .success)
        } catch {
            print("❌ DEBUG: Snapshot creation failed: \(error)")
            toast = Toast(message: "snapshot_create_error".localized + "\n\n" + error.localizedDescription, type: .error)
        }
    }
    
    /// Delete the specified snapshot
    func deleteSnapshot(_ snap: Snapshot) {
        do {
            try QemuManager.shared.deleteSnapshot(vm: vm, name: snap.tag)
            refreshSnapshots()
            toast = Toast(message: "snapshot_deleted_success".localized, type: .success)
        } catch {
            toast = Toast(message: "snapshot_delete_error".localized + "\n\n" + error.localizedDescription, type: .error)
        }
    }
    
    /// Restore the VM to the specified snapshot state
    func restoreSnapshot(_ snap: Snapshot) {
        do {
            try QemuManager.shared.restoreSnapshot(vm: vm, name: snap.tag)
            toast = Toast(message: "snapshot_restored_success".localized, type: .success)
        } catch {
            toast = Toast(message: "snapshot_restore_error".localized + "\n\n" + error.localizedDescription, type: .error)
        }
    }
}
