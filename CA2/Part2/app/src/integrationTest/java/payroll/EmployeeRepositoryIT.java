package payroll;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
class EmployeeRepositoryIT {

    @Autowired
    private EmployeeRepository repo;

    @Test
    void shouldPersistAndLoadEmployee() {
        Employee e = new Employee("Nuno", "Cunha", "Developer");
        repo.save(e); // H2 in-memory

        Optional<Employee> found = repo.findById(e.getId());
        assertThat(found).isPresent();
        assertThat(found.get().getName()).isEqualTo("Nuno Cunha");
        assertThat(found.get().getRole()).isEqualTo("Developer");
    }
}
