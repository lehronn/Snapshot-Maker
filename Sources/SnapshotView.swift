import SwiftUI

struct SnapshotView: View {
    let vm: VirtualMachine
    @State private var snapshots: [Snapshot] = []
    @State private var newSnapshotName: String = ""
    @State private var toast: Toast?
    
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
                                restoreSnapshot(snap)
                            }
                            
                            Button("delete_snapshot".localized) {
                                deleteSnapshot(snap)
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
    }
    
    func refreshSnapshots() {
        snapshots = QemuManager.shared.listSnapshots(vm: vm)
    }
    
    func createSnapshot() {
        do {
            try QemuManager.shared.createSnapshot(vm: vm, name: newSnapshotName)
            newSnapshotName = ""
            refreshSnapshots()
            toast = Toast(message: "snapshot_created_success".localized, type: .success)
        } catch {
            toast = Toast(message: "snapshot_create_error".localized + "\n\n" + error.localizedDescription, type: .error)
        }
    }
    
    func deleteSnapshot(_ snap: Snapshot) {
        do {
            try QemuManager.shared.deleteSnapshot(vm: vm, name: snap.tag)
            refreshSnapshots()
            toast = Toast(message: "snapshot_deleted_success".localized, type: .success)
        } catch {
            toast = Toast(message: "snapshot_delete_error".localized + "\n\n" + error.localizedDescription, type: .error)
        }
    }
    
    func restoreSnapshot(_ snap: Snapshot) {
        do {
            try QemuManager.shared.restoreSnapshot(vm: vm, name: snap.tag)
            toast = Toast(message: "snapshot_restored_success".localized, type: .success)
        } catch {
            toast = Toast(message: "snapshot_restore_error".localized + "\n\n" + error.localizedDescription, type: .error)
        }
    }
}
