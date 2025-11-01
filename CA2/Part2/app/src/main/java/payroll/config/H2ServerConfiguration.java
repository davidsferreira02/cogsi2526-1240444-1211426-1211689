package payroll.config;

import org.h2.tools.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

import java.sql.SQLException;

/**
 * Starts an H2 TCP server so the application connects in server mode instead of in-memory/file mode.
 * This bean is only active for the "dev" profile.
 */
@Configuration
@Profile("dev")
public class H2ServerConfiguration {

    /**
     * Starts the H2 TCP server on port 9092 and allows local and VM access.
     * The server is stopped automatically on context shutdown.
     */
    @Bean(initMethod = "start", destroyMethod = "stop")
    public Server h2TcpServer() throws SQLException {
        // -tcpAllowOthers lets connections from the Vagrant host; restrict in production environments
        return Server.createTcpServer("-tcp", "-tcpAllowOthers", "-tcpPort", "9092");
    }
}
