package org.springframework.samples.petclinic.model;

import java.util.Locale;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validator;



class VetTests {

    private LocalValidatorFactoryBean localValidatorFactoryBean;

    @BeforeEach
    void setUp() {
        localValidatorFactoryBean = new LocalValidatorFactoryBean();
        localValidatorFactoryBean.afterPropertiesSet();
        LocaleContextHolder.setLocale(Locale.ENGLISH);
    }

    @AfterEach
    void tearDown() {
        localValidatorFactoryBean.close();
    }

    @Test
    void shouldSetAndGetProfessionalNumber() {
       
        Vet vet = new Vet();
        vet.setFirstName("John");
        vet.setLastName("Doe");
        String professionalNumber = "1234567890";

        vet.setProfessionalNumber(professionalNumber);

       
        assertThat(vet.getProfessionalNumber()).isEqualTo(professionalNumber);
    }

    @Test
    void shouldNotValidateWhenProfessionalNumberIsEmpty() {
      
        Vet vet = createValidVet();
        vet.setProfessionalNumber("");

        
        Validator validator = createValidator();
        Set<ConstraintViolation<Vet>> constraintViolations = validator.validate(vet);

        
        assertThat(constraintViolations).hasSize(2); 
        
        Set<String> messages = constraintViolations.stream()
            .map(ConstraintViolation::getMessage)
            .collect(java.util.stream.Collectors.toSet());
        
        assertThat(messages).containsExactlyInAnyOrder(
            "must not be empty",
            "numeric value out of bounds (<10 digits>.<0 digits> expected)"
        );
        
       
        for (ConstraintViolation<Vet> violation : constraintViolations) {
            assertThat(violation.getPropertyPath()).hasToString("professionalNumber");
        }
    }

    @Test
    void shouldNotValidateWhenProfessionalNumberIsNull() {
        
        Vet vet = createValidVet();
        vet.setProfessionalNumber(null);

        
        Validator validator = createValidator();
        Set<ConstraintViolation<Vet>> constraintViolations = validator.validate(vet);

        
        assertThat(constraintViolations).hasSize(1);
        ConstraintViolation<Vet> violation = constraintViolations.iterator().next();
        assertThat(violation.getPropertyPath()).hasToString("professionalNumber");
        assertThat(violation.getMessage()).isEqualTo("must not be empty");
    }

  

    private Vet createValidVet() {
        Vet vet = new Vet();
        vet.setFirstName("John");
        vet.setLastName("Doe");
        vet.setProfessionalNumber("1234567890");
        return vet;
    }

    
    private Validator createValidator() {
        return localValidatorFactoryBean.getValidator();
    }
}