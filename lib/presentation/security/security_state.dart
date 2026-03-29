sealed class SecurityState {
  const SecurityState();

  bool get isLocked => this is SecurityLocked;
}

class SecurityUnlocked extends SecurityState {
  const SecurityUnlocked();
}

class SecurityLocked extends SecurityState {
  const SecurityLocked();
}
