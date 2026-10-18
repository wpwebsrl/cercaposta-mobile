import java.io.ByteArrayOutputStream;
import java.io.StringReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Properties;

/** Normalize only SDK path properties after Flutter 3.32 generates Windows paths. */
public class NormalizeAndroidSdkPaths {
    public static void main(String[] args) throws Exception {
        Path file = Path.of(args.length == 0 ? "android/local.properties" : args[0]);
        String original = Files.readString(file, StandardCharsets.UTF_8);
        Properties source = new Properties();
        source.load(new StringReader(original));
        String newline = original.contains("\r\n") ? "\r\n" : "\n";
        String[] lines = original.split("\\r?\\n", -1);
        int changes = 0;
        for (String key : new String[] {"sdk.dir", "flutter.sdk"}) {
            String value = source.getProperty(key);
            if (value == null) continue;
            Properties normalized = new Properties();
            normalized.setProperty(key, Path.of(value).normalize().toString().replace('\\', '/'));
            ByteArrayOutputStream encoded = new ByteArrayOutputStream();
            normalized.store(encoded, null);
            String replacement = encoded.toString(StandardCharsets.ISO_8859_1).lines()
                .filter(line -> line.startsWith(key + "=")).findFirst().orElseThrow();
            for (int i = 0; i < lines.length; i++) {
                if (lines[i].startsWith(key + "=") && !lines[i].equals(replacement)) {
                    lines[i] = replacement;
                    changes++;
                }
            }
        }
        String result = String.join(newline, lines);
        if (!result.equals(original)) {
            Path temporary = Files.createTempFile(file.toAbsolutePath().getParent(), ".sdk-paths-", ".tmp");
            try {
                Files.writeString(temporary, result, StandardCharsets.UTF_8);
                Files.move(temporary, file.toAbsolutePath(), StandardCopyOption.REPLACE_EXISTING);
            } finally {
                Files.deleteIfExists(temporary);
            }
        }
        System.out.println("Normalized SDK path properties: " + changes);
    }
}
