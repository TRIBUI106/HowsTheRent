package chez1s.htrbackend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class HtrBackendApplication {


    public static void main(String[] args) {
        SpringApplication.run(HtrBackendApplication.class, args);
    }

}
