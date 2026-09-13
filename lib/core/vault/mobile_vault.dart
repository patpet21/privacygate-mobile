abstract interface class MobileVault {
  Future<void> saveProtectedArtifact(String artifactId, String protectedText);
  Future<void> deleteSession(String sessionId);
}
