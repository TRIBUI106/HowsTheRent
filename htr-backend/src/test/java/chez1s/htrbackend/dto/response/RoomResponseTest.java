package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.enums.RoomDirection;
import chez1s.htrbackend.domain.enums.RoomStatus;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class RoomResponseTest {

    private Room.RoomBuilder roomWithProperty() {
        Property property = Property.builder()
                .id(UUID.randomUUID())
                .name("Toà nhà A")
                .build();
        return Room.builder()
                .id(UUID.randomUUID())
                .property(property)
                .roomNumber("101")
                .maxPeople(2)
                .status(RoomStatus.EMPTY);
    }

    @Test
    void from_mapsDirectionNameWhenSet() {
        Room room = roomWithProperty().direction(RoomDirection.SOUTHEAST).build();

        RoomResponse response = RoomResponse.from(room);

        assertThat(response.direction()).isEqualTo("SOUTHEAST");
    }

    @Test
    void from_leavesDirectionNullWhenUnset() {
        Room room = roomWithProperty().build();

        RoomResponse response = RoomResponse.from(room);

        assertThat(response.direction()).isNull();
    }
}
