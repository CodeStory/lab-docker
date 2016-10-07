import com.google.common.base.Supplier;
import com.google.common.base.Suppliers;
import com.mongodb.DB;
import com.mongodb.MongoClient;
import com.mongodb.MongoClientOptions;
import net.codestory.http.WebServer;
import net.codestory.http.filters.log.LogRequestFilter;
import org.jongo.Jongo;

import java.net.UnknownHostException;
import java.util.List;
import java.util.Random;

@SuppressWarnings("ALL")
public class Main {
    public static void main(String[] args) throws UnknownHostException {
        Supplier<Jongo> jongo = Suppliers.memoize(() -> createJongo());

        Supplier<WordResponse> noun1 = Suppliers.memoize(() -> randomWord("nouns", jongo));
        Supplier<WordResponse> noun2 = Suppliers.memoize(() -> randomWord("nouns", jongo));
        Supplier<WordResponse> adjective1 = Suppliers.memoize(() -> randomWord("adjectives", jongo));
        Supplier<WordResponse> adjective2 = Suppliers.memoize(() -> randomWord("adjectives", jongo));
        Supplier<WordResponse> verb = Suppliers.memoize(() -> randomWord("verbs", jongo));

        new WebServer().configure(routes -> routes
                .filter(LogRequestFilter.class)
                .filter(AddHostName.class)
                .get("/noun1", () -> noun1.get())
                .get("/adjective1", () -> adjective1.get())
                .get("/verb", () -> verb.get())
                .get("/noun2", () -> noun2.get())
                .get("/adjective2", () -> adjective2.get())
        ).start();
    }

    private static WordResponse randomWord(String set, Supplier<Jongo> jongo) {
        Words words = new Words(jongo.get(), set);

        switch (set) {
            case "nouns":
                words.addIfEmpty("dead body", "elephant", "go language", "laptop", "container", "micro-service", "turtle", "whale");
                break;
            case "verbs":
                words.addIfEmpty("will drink", "smashed", "smokes", "eats", "walks towards", "loves", "helps", "pushes", "debugs");
                break;
            case "adjectives":
                words.addIfEmpty("the exquisite", "a pink", "the rotten", "a red", "the floating", "a broken", "a shiny", "the pretty", "the impressive", "an awesome");
                break;
        }

        Random random = new Random();
        List<String> all = words.all();
        String word = all.get(random.nextInt(all.size()));

        return new WordResponse(word, null);
    }

    private static Jongo createJongo() {
        DB db = new MongoClient("mongo:27017", new MongoClientOptions.Builder()
                .serverSelectionTimeout(2000)
                .build()).getDB("lab-docker");

        return new Jongo(db);
    }
}
