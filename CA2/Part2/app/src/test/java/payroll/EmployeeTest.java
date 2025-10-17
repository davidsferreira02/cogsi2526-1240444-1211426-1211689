package payroll;

import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;


class EmployeeTest {

    @Test
    void constructorAndGetters_shouldReturnCorrectValues() {
        Employee e = new Employee("Nuno", "Cunha", "Developer");

        assertThat(e.getFirstName()).isEqualTo("Nuno");
        assertThat(e.getLastName()).isEqualTo("Cunha");
        assertThat(e.getRole()).isEqualTo("Developer");
        assertThat(e.getName()).isEqualTo("Nuno Cunha");
    }
}