package payroll;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
class OrderRepositoryIT {

    @Autowired
    private OrderRepository repo;

    @Test
    void shouldPersistAndRetrieveOrder() {
        Order order = new Order("Laptop", Status.IN_PROGRESS);
        repo.save(order);

        Optional<Order> found = repo.findById(order.getId());
        assertThat(found).isPresent();
        assertThat(found.get().getDescription()).isEqualTo("Laptop");
        assertThat(found.get().getStatus()).isEqualTo(Status.IN_PROGRESS);
    }
}