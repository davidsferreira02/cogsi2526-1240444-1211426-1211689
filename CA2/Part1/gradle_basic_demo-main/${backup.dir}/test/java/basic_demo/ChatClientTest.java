package basic_demo;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class ChatClientTest {

    @Test
    void testChatClientCreation() {
        ChatClient client = new ChatClient("localhost", 59001);
        assertNotNull(client, "ChatClient Created with Success");
    }
}