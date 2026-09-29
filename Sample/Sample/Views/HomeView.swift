import SwiftUI
import MIRACLTrust

struct HomeView: View {
    @Binding var navigationPath: [Destination]
    let onError: (String) -> Void

    @State private var users: [User] = []
    @State private var isLoading = true
    @State private var userToDelete: User?

    private var isDeleteConfirmationPresented: Binding<Bool> {
        Binding(
            get: { userToDelete != nil },
            set: { if !$0 { userToDelete = nil } }
        )
    }

    var body: some View {
        mainContent
            .navigationTitle("MIRACL Trust")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        navigationPath.append(.enterUserId())
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .onAppear { loadUsers() }
            .confirmationDialog(
                "Remove User?",
                isPresented: isDeleteConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("Remove User", role: .destructive) { deleteSelectedUser() }
                Button("Cancel", role: .cancel) { userToDelete = nil }
            } message: {
                Text("You will no longer be able to authenticate with this device.")
            }
    }

    @ViewBuilder
    private var mainContent: some View {
        if isLoading {
            ProgressView("Loading users...")
        } else if users.isEmpty {
            ContentUnavailableView(
                "No Registered Users",
                systemImage: "person.slash",
                description: Text("Register a User ID to start using MIRACL Trust.")
            )
        } else {
            userListView
        }
    }

    private var userListView: some View {
        List {
            Section("Registered Users") {
                ForEach(users, id: \.userId) { user in
                    userRow(for: user)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func userRow(for user: User) -> some View {
        let targetDestination: Destination
        if user.revoked {
            targetDestination = .revoked(userId: user.userId)
        } else {
            targetDestination = .authentication(userId: user.userId)
        }
        
        return NavigationLink(value: targetDestination) {
            VStack(alignment: .leading, spacing: 4) {
                Text(user.userId)
                    .font(.body)
                    .foregroundColor(.primary)
                if user.revoked {
                    Text("Disabled")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                userToDelete = user
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func deleteSelectedUser() {
        guard let user = userToDelete else { return }
        MIRACLTrust.getInstance().delete(user: user) { _, error in
            userToDelete = nil
            if let error = error {
                onError(error.localizedDescription)
            } else {
                loadUsers()
            }
        }
    }

    private func loadUsers() {
        MIRACLTrust.getInstance().getUsers { rawUsers, error in
            if let error = error {
                onError(error.localizedDescription)
            } else if let allUsers = rawUsers {
                self.users = allUsers.filter { $0.projectId == MIRACLTrustConfig.projectId }
            }
            self.isLoading = false
        }
    }
}
