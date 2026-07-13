package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.*;
import chez1s.htrbackend.domain.enums.MaintenanceStatus;
import chez1s.htrbackend.domain.repository.*;
import chez1s.htrbackend.dto.request.CreateMaintenanceMaterial;
import chez1s.htrbackend.dto.request.CreateMaintenanceRequest;
import chez1s.htrbackend.exception.BadRequestException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MaintenanceServiceTest {

    @Mock
    private MaintenanceRequestRepository maintenanceRepository;
    @Mock
    private ContractRepository contractRepository;
    @Mock
    private RoomService roomService;
    @Mock
    private UserRepository userRepository;
    @Mock
    private NotificationService notificationService;
    @Mock
    private MaintenanceMaterialRepository materialRepository;
    @Mock
    private MaintenanceNoteRepository noteRepository;
    @Spy
    private MaintenanceStateTransitionValidator transitionValidator = new MaintenanceStateTransitionValidator();
    @Mock
    private SlaService slaService;

    @InjectMocks
    private MaintenanceService maintenanceService;

    private UUID tenantId;
    private UUID techId;
    private UUID requestId;
    private MaintenanceRequest sampleRequest;
    private User tenant;
    private User tech;
    private Room room;

    @BeforeEach
    void setup() {
        tenantId = UUID.randomUUID();
        techId = UUID.randomUUID();
        requestId = UUID.randomUUID();

        tenant = User.builder().id(tenantId).fullName("Tenant Name").build();
        tech = User.builder().id(techId).fullName("Tech Name").build();
        room = Room.builder().id(UUID.randomUUID()).roomNumber("101").property(Property.builder().id(UUID.randomUUID()).owner(User.builder().id(UUID.randomUUID()).build()).build()).build();

        sampleRequest = MaintenanceRequest.builder()
                .id(requestId)
                .room(room)
                .tenant(tenant)
                .title("Test Issue")
                .description("Detailed description over 10 chars")
                .status(MaintenanceStatus.OPEN)
                .images(new ArrayList<>())
                .completionImages(new ArrayList<>())
                .preferredTimeSlots(new ArrayList<>())
                .build();
        lenient().when(slaService.calculateExpectedResolvedAt(any(), any())).thenReturn(java.time.LocalDateTime.now().plusHours(1));
    }

    @Test
    void createRequest_ValidDescription_Success() {
        CreateMaintenanceRequest req = new CreateMaintenanceRequest();
        req.setRoomId(room.getId());
        req.setTitle("Leak problem");
        req.setDescription("Water is leaking from the sink loudly");
        
        when(roomService.getById(room.getId())).thenReturn(room);
        when(userRepository.findById(tenantId)).thenReturn(Optional.of(tenant));
        when(maintenanceRepository.save(any(MaintenanceRequest.class))).thenAnswer(i -> {
            MaintenanceRequest arg = i.getArgument(0);
            arg.setId(requestId);
            return arg;
        });
        when(maintenanceRepository.findById(requestId)).thenReturn(Optional.of(sampleRequest));
        when(noteRepository.save(any(MaintenanceNote.class))).thenAnswer(i -> {
            MaintenanceNote note = i.getArgument(0);
            note.setId(UUID.randomUUID());
            return note;
        });

        MaintenanceRequest result = maintenanceService.create(tenantId, req);

        assertNotNull(result.getTicketCode());
        assertEquals("Leak problem", result.getTitle());
        assertEquals(MaintenanceStatus.OPEN, result.getStatus());
        verify(notificationService, times(1)).create(any(), any(), any(), any(), any());
    }

    @Test
    void createRequest_ShortDescription_ThrowsBadRequest() {
        CreateMaintenanceRequest req = new CreateMaintenanceRequest();
        req.setTitle("Leak");
        req.setDescription("Short");

        assertThrows(BadRequestException.class, () -> maintenanceService.create(tenantId, req));
    }

    @Test
    void assign_ValidTransition_Success() {
        when(maintenanceRepository.findById(requestId)).thenReturn(Optional.of(sampleRequest));
        when(userRepository.findById(techId)).thenReturn(Optional.of(tech));
        when(maintenanceRepository.countByAssignedToIdAndStatusNotIn(eq(techId), anyList())).thenReturn(2L);
        when(maintenanceRepository.save(any(MaintenanceRequest.class))).thenAnswer(i -> i.getArgument(0));
        when(noteRepository.save(any(MaintenanceNote.class))).thenAnswer(i -> {
            MaintenanceNote note = i.getArgument(0);
            note.setId(UUID.randomUUID());
            return note;
        });

        MaintenanceRequest result = maintenanceService.assign(requestId, techId);

        assertEquals(MaintenanceStatus.ASSIGNED, result.getStatus());
        assertEquals(tech, result.getAssignedTo());
    }

    @Test
    void startWork_ValidTransition_SetsStartedAt() {
        sampleRequest.setStatus(MaintenanceStatus.ASSIGNED);
        when(maintenanceRepository.findById(requestId)).thenReturn(Optional.of(sampleRequest));
        when(maintenanceRepository.save(any(MaintenanceRequest.class))).thenAnswer(i -> i.getArgument(0));
        when(noteRepository.save(any(MaintenanceNote.class))).thenAnswer(i -> {
            MaintenanceNote note = i.getArgument(0);
            note.setId(UUID.randomUUID());
            return note;
        });

        MaintenanceRequest result = maintenanceService.startWork(requestId);

        assertEquals(MaintenanceStatus.IN_PROGRESS, result.getStatus());
        assertNotNull(result.getStartedAt());
    }

    @Test
    void cancel_ShortReason_ThrowsBadRequest() {
        assertThrows(BadRequestException.class, () -> maintenanceService.cancel(requestId, "short"));
    }

    @Test
    void addMaterial_UpdatesTotalCost() {
        when(maintenanceRepository.findById(requestId)).thenReturn(Optional.of(sampleRequest));
        when(materialRepository.save(any(MaintenanceMaterial.class))).thenAnswer(i -> {
            MaintenanceMaterial mat = i.getArgument(0);
            mat.setId(UUID.randomUUID());
            return mat;
        });
        when(materialRepository.findByRequestIdOrderByCreatedAtAsc(requestId)).thenReturn(List.of(
                MaintenanceMaterial.builder().id(UUID.randomUUID()).request(sampleRequest).totalPrice(BigDecimal.valueOf(150000)).isFreeInContract(false).build()
        ));
        when(noteRepository.save(any(MaintenanceNote.class))).thenAnswer(i -> {
            MaintenanceNote note = i.getArgument(0);
            note.setId(UUID.randomUUID());
            return note;
        });

        CreateMaintenanceMaterial req = new CreateMaintenanceMaterial();
        req.setName("Van nước");
        req.setQuantity(1);
        req.setUnitPrice(BigDecimal.valueOf(150000));

        maintenanceService.addMaterial(requestId, req);

        assertEquals(BigDecimal.valueOf(150000), sampleRequest.getMaterialCost());
    }
}
