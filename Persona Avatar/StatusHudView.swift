
    private var statusHUD: some View {
        VStack(spacing: 8) {
            Text("Status").font(.headline)
            Text("All green ✅").font(.subheadline)
        }
        .padding(14)
        .glassBackgroundEffect()
    }