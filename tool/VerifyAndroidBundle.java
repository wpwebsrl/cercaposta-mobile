import java.io.InputStream;
import java.nio.file.Path;
import java.security.CodeSigner;
import java.security.MessageDigest;
import java.security.cert.X509Certificate;
import java.util.HexFormat;
import java.util.Locale;
import java.util.HashSet;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;

/** Verifies the AAB's JAR signatures, every payload entry, and the approved upload certificate. */
public final class VerifyAndroidBundle {
    public static void main(String[] args) {
        try {
            if (args.length != 2 || !args[1].matches("[a-fA-F0-9]{64}")) {
                throw new SecurityException("Expected AAB path and SHA-256 of the approved upload certificate");
            }
            byte[] expected = HexFormat.of().parseHex(args[1]);
            int verified = 0;
            long total = 0;
            boolean manifestFound = false;
            var names = new HashSet<String>();
            try (JarFile jar = new JarFile(Path.of(args[0]).toFile(), true)) {
                var entries = jar.entries();
                byte[] buffer = new byte[64 * 1024];
                while (entries.hasMoreElements()) {
                    JarEntry entry = entries.nextElement();
                    if (!names.add(entry.getName()) || entry.getName().startsWith("/") ||
                        entry.getName().contains("\\") || entry.getName().matches("(^|.*/)\\.\\.?(/.*|$)")) {
                        throw new SecurityException("Ambiguous bundle entry path");
                    }
                    if (entry.isDirectory()) continue;
                    String name = entry.getName().toUpperCase(Locale.ROOT);
                    if (name.equals("META-INF/MANIFEST.MF") || name.matches("META-INF/[^/]+\\.(SF|RSA|DSA|EC)")) continue;
                    // Reading the complete entry triggers the JDK's cryptographic verifier.
                    try (InputStream stream = jar.getInputStream(entry)) {
                        int count;
                        while ((count = stream.read(buffer)) != -1) {
                            total += count;
                            if (total > 2L * 1024 * 1024 * 1024) throw new SecurityException("Bundle exceeds verification limit");
                        }
                    }
                    CodeSigner[] signers = entry.getCodeSigners();
                    if (signers == null || signers.length != 1) throw new SecurityException("Unsigned or ambiguous bundle entry");
                    X509Certificate cert = (X509Certificate) signers[0].getSignerCertPath().getCertificates().get(0);
                    cert.checkValidity();
                    String subject = cert.getSubjectX500Principal().getName().toLowerCase(Locale.ROOT);
                    if (subject.contains("cn=android debug")) throw new SecurityException("Debug certificates cannot sign a release");
                    byte[] actual = MessageDigest.getInstance("SHA-256").digest(cert.getEncoded());
                    if (!MessageDigest.isEqual(expected, actual)) throw new SecurityException("Unexpected upload certificate");
                    if (++verified > 50000) throw new SecurityException("Too many bundle entries");
                    if (entry.getName().equals("base/manifest/AndroidManifest.xml")) manifestFound = true;
                }
            }
            if (verified == 0 || !manifestFound) throw new SecurityException("No signed Android app payload");
            System.out.println("Verified Android bundle: " + verified + " signed payload entries; certificate SHA-256 " + args[1].toLowerCase(Locale.ROOT));
        } catch (Exception error) {
            System.err.println("Android release verification failed: " + error.getClass().getSimpleName());
            System.exit(1);
        }
    }
}
