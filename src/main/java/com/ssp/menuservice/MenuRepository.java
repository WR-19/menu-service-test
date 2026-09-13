package com.ssp.menuservice;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

/**
 * Stands in for a real menu database. The databaseUp flag is read from
 * application properties so it can be flipped to simulate an outage
 * without touching code, the same way a real DB connection could drop.
 */
@Component
public class MenuRepository {

    @Value("${menu.database.up:true}")
    private boolean databaseUp;

    private static final Map<String, List<String>> MENUS = Map.of(
            "LHR-T5-001", List.of("Bacon roll", "Flat white", "Orange juice"),
            "MAN-T1-004", List.of("Chicken sandwich", "Latte", "Water")
    );

    public List<String> findMenu(String unitId) {
        if (!databaseUp) {
            throw new IllegalStateException("Menu database is unreachable");
        }
        List<String> menu = MENUS.get(unitId);
        if (menu == null) {
            throw new NoSuchUnitException(unitId);
        }
        return menu;
    }

    public boolean isDatabaseUp() {
        return databaseUp;
    }
}
