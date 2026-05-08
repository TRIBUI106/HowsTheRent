package chez1s.htrbackend;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class GenHash {
    public static void main(String[] args) {
        String[] passwords = {"Admin123!", "Tenant123!", "Tech123!"};
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        for (String p : passwords) {
            System.out.println(p + " => " + encoder.encode(p));
        }
    }
}
