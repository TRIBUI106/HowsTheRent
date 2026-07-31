package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.*;
import chez1s.htrbackend.controller.MaintenanceController;
import chez1s.htrbackend.domain.enums.MaintenanceStatus;
import chez1s.htrbackend.domain.enums.MaintenanceCategory;
import chez1s.htrbackend.domain.enums.MaintenancePriority;
import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.domain.repository.*;
import chez1s.htrbackend.dto.request.CreateMaintenanceMaterial;
import chez1s.htrbackend.dto.request.CreateMaintenanceRequest;
import chez1s.htrbackend.exception.BadRequestException;
import chez1s.htrbackend.service.StorageService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.aop.framework.ProxyFactory;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.annotation.AnnotationTransactionAttributeSource;
import org.springframework.transaction.interceptor.TransactionInterceptor;
import org.springframework.transaction.support.AbstractPlatformTransactionManager;
import org.springframework.transaction.support.DefaultTransactionStatus;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.AbstractList;
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
        tech = User.builder().id(techId).fullName("Tech Name").role(chez1s.htrbackend.domain.enums.UserRole.TECHNICIAN).active(true).build();
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
    void listByTenant_MaterializesLazyCollectionsWithinReadOnlyTransaction() {
        sampleRequest.setImages(transactionBoundList("request.jpg"));
        sampleRequest.setPreferredTimeSlots(transactionBoundList("Sáng"));
        sampleRequest.setCompletionImages(transactionBoundList("completed.jpg"));
        var pageable = PageRequest.of(0, 20);
        when(maintenanceRepository.findByTenantId(tenantId, pageable))
                .thenReturn(new PageImpl<>(List.of(sampleRequest), pageable, 1));

        var transactionManager = new TestTransactionManager();
        var interceptor = new TransactionInterceptor(
                transactionManager,
                new AnnotationTransactionAttributeSource()
        );
        ProxyFactory proxyFactory = new ProxyFactory(maintenanceService);
        proxyFactory.addAdvice(interceptor);
        MaintenanceService proxiedService = (MaintenanceService) proxyFactory.getProxy();

        var response = proxiedService.listByTenant(tenantId, pageable);

        assertEquals(List.of("request.jpg"), response.content().getFirst().images());
        assertEquals(List.of("Sáng"), response.content().getFirst().preferredTimeSlots());
        assertEquals(List.of("completed.jpg"), response.content().getFirst().completionImages());
        assertFalse(response.content().getFirst().images() instanceof TransactionBoundList);
        assertFalse(response.content().getFirst().preferredTimeSlots() instanceof TransactionBoundList);
        assertFalse(response.content().getFirst().completionImages() instanceof TransactionBoundList);
        assertTrue(transactionManager.isReadOnly());
    }

    @Test
    void listAllByOwner_MaterializesLazyCollectionsWithinReadOnlyTransaction() {
        UUID adminId = UUID.randomUUID();
        sampleRequest.setImages(transactionBoundList("request.jpg"));
        sampleRequest.setPreferredTimeSlots(transactionBoundList("Sáng"));
        sampleRequest.setCompletionImages(transactionBoundList("completed.jpg"));
        var pageable = PageRequest.of(0, 20);
        when(userRepository.findById(adminId))
                .thenReturn(Optional.of(User.builder().id(adminId).role(UserRole.ADMIN).build()));
        when(maintenanceRepository.findAll(pageable))
                .thenReturn(new PageImpl<>(List.of(sampleRequest), pageable, 1));

        var transactionManager = new TestTransactionManager();
        MaintenanceService proxiedService = transactionalProxy(transactionManager);

        var response = proxiedService.listAllByOwner(adminId, pageable);

        assertEquals(List.of("request.jpg"), response.content().getFirst().images());
        assertEquals(List.of("Sáng"), response.content().getFirst().preferredTimeSlots());
        assertEquals(List.of("completed.jpg"), response.content().getFirst().completionImages());
        assertTrue(transactionManager.isReadOnly());
    }

    @Test
    void listFiltered_MaterializesLazyCollectionsWithinReadOnlyTransaction() {
        UUID adminId = UUID.randomUUID();
        sampleRequest.setImages(transactionBoundList("request.jpg"));
        sampleRequest.setPreferredTimeSlots(transactionBoundList("Sáng"));
        sampleRequest.setCompletionImages(transactionBoundList("completed.jpg"));
        var pageable = PageRequest.of(0, 20);
        var statuses = List.of(MaintenanceStatus.OPEN);
        when(userRepository.findById(adminId))
                .thenReturn(Optional.of(User.builder().id(adminId).role(UserRole.ADMIN).build()));
        when(maintenanceRepository.findByStatusIn(statuses, pageable))
                .thenReturn(new PageImpl<>(List.of(sampleRequest), pageable, 1));

        var transactionManager = new TestTransactionManager();
        MaintenanceService proxiedService = transactionalProxy(transactionManager);

        var response = proxiedService.listFiltered(adminId, statuses, pageable);

        assertEquals(List.of("request.jpg"), response.content().getFirst().images());
        assertEquals(List.of("Sáng"), response.content().getFirst().preferredTimeSlots());
        assertEquals(List.of("completed.jpg"), response.content().getFirst().completionImages());
        assertTrue(transactionManager.isReadOnly());
    }

    @Test
    void listAssigned_MaterializesLazyCollectionsWithinReadOnlyTransaction() {
        sampleRequest.setImages(transactionBoundList("request.jpg"));
        sampleRequest.setPreferredTimeSlots(transactionBoundList("Sáng"));
        sampleRequest.setCompletionImages(transactionBoundList("completed.jpg"));
        when(maintenanceRepository.findByAssignedToIdOrderByCreatedAtDesc(techId))
                .thenReturn(List.of(sampleRequest));
        Authentication authentication = mock(Authentication.class);
        when(authentication.getPrincipal()).thenReturn(techId);

        var transactionManager = new TestTransactionManager();
        MaintenanceService proxiedService = transactionalProxy(transactionManager);
        MaintenanceController controller = new MaintenanceController(proxiedService, mock(StorageService.class));

        var response = controller.listAssigned(authentication).getBody();

        assertNotNull(response);
        assertEquals(List.of("request.jpg"), response.getFirst().images());
        assertEquals(List.of("Sáng"), response.getFirst().preferredTimeSlots());
        assertEquals(List.of("completed.jpg"), response.getFirst().completionImages());
        assertTrue(transactionManager.isReadOnly());
    }

    @Test
    void actionResponse_MaterializesLazyCollectionsAfterWriteTransaction() {
        sampleRequest.setStatus(MaintenanceStatus.ASSIGNED);
        sampleRequest.setImages(transactionBoundList("request.jpg"));
        sampleRequest.setPreferredTimeSlots(transactionBoundList("Sáng"));
        sampleRequest.setCompletionImages(transactionBoundList("completed.jpg"));
        when(maintenanceRepository.findById(requestId)).thenReturn(Optional.of(sampleRequest));
        when(maintenanceRepository.save(sampleRequest)).thenReturn(sampleRequest);
        when(noteRepository.save(any(MaintenanceNote.class))).thenAnswer(invocation -> invocation.getArgument(0));

        var transactionManager = new TestTransactionManager();
        MaintenanceService proxiedService = transactionalProxy(transactionManager);
        MaintenanceController controller = new MaintenanceController(proxiedService, mock(StorageService.class));

        var response = controller.startWork(requestId).getBody();

        assertNotNull(response);
        assertEquals(List.of("request.jpg"), response.images());
        assertEquals(List.of("Sáng"), response.preferredTimeSlots());
        assertEquals(List.of("completed.jpg"), response.completionImages());
    }

    @Test
    void getById_MaterializesLazyCollectionsWithinReadOnlyTransaction() {
        sampleRequest.setImages(transactionBoundList("request.jpg"));
        sampleRequest.setPreferredTimeSlots(transactionBoundList("Sáng"));
        sampleRequest.setCompletionImages(transactionBoundList("completed.jpg"));
        when(maintenanceRepository.findById(requestId)).thenReturn(Optional.of(sampleRequest));

        var transactionManager = new TestTransactionManager();
        MaintenanceService proxiedService = transactionalProxy(transactionManager);
        MaintenanceController controller = new MaintenanceController(proxiedService, mock(StorageService.class));

        var response = controller.getById(requestId).getBody();

        assertNotNull(response);
        assertEquals(List.of("request.jpg"), response.images());
        assertEquals(List.of("Sáng"), response.preferredTimeSlots());
        assertEquals(List.of("completed.jpg"), response.completionImages());
        assertTrue(transactionManager.isReadOnly());
    }

    @Test
    void listMaterials_MapsLazyRequestWithinReadOnlyTransaction() {
        MaintenanceMaterial material = mock(MaintenanceMaterial.class);
        when(materialRepository.findByRequestIdOrderByCreatedAtAsc(requestId))
                .thenReturn(List.of(material));
        when(material.getId()).thenReturn(UUID.randomUUID());
        when(material.getRequest()).thenAnswer(invocation -> {
            if (!TransactionSynchronizationManager.isActualTransactionActive()) {
                throw new IllegalStateException("Lazy request accessed outside transaction");
            }
            return sampleRequest;
        });
        when(material.getName()).thenReturn("Filter");
        when(material.getQuantity()).thenReturn(1);
        when(material.getUnit()).thenReturn("cái");
        when(material.getUnitPrice()).thenReturn(BigDecimal.TEN);
        when(material.getTotalPrice()).thenReturn(BigDecimal.TEN);
        when(material.getIsFreeInContract()).thenReturn(false);
        when(material.getCreatedAt()).thenReturn(LocalDateTime.now());

        var transactionManager = new TestTransactionManager();
        MaintenanceService proxiedService = transactionalProxy(transactionManager);

        var response = proxiedService.listMaterials(requestId);

        assertEquals(requestId, response.getFirst().requestId());
        assertTrue(transactionManager.isReadOnly());
    }

    @Test
    void listNotes_MapsLazyRequestAndActorWithinReadOnlyTransaction() {
        MaintenanceNote note = mock(MaintenanceNote.class);
        when(noteRepository.findByRequestIdOrderByCreatedAtDesc(requestId))
                .thenReturn(List.of(note));
        when(note.getId()).thenReturn(UUID.randomUUID());
        when(note.getRequest()).thenAnswer(invocation -> {
            if (!TransactionSynchronizationManager.isActualTransactionActive()) {
                throw new IllegalStateException("Lazy request accessed outside transaction");
            }
            return sampleRequest;
        });
        when(note.getActor()).thenAnswer(invocation -> {
            if (!TransactionSynchronizationManager.isActualTransactionActive()) {
                throw new IllegalStateException("Lazy actor accessed outside transaction");
            }
            return tech;
        });
        when(note.getStatus()).thenReturn(MaintenanceStatus.OPEN);
        when(note.getNote()).thenReturn("Đã kiểm tra phiếu bảo trì");
        when(note.getCreatedAt()).thenReturn(LocalDateTime.now());

        var transactionManager = new TestTransactionManager();
        MaintenanceService proxiedService = transactionalProxy(transactionManager);

        var response = proxiedService.listNotes(requestId);

        assertEquals(requestId, response.getFirst().requestId());
        assertEquals(techId, response.getFirst().actorId());
        assertEquals("Tech Name", response.getFirst().actorName());
        assertTrue(transactionManager.isReadOnly());
    }

    private MaintenanceService transactionalProxy(TestTransactionManager transactionManager) {
        var interceptor = new TransactionInterceptor(
                transactionManager,
                new AnnotationTransactionAttributeSource()
        );
        ProxyFactory proxyFactory = new ProxyFactory(maintenanceService);
        proxyFactory.addAdvice(interceptor);
        return (MaintenanceService) proxyFactory.getProxy();
    }

    private static List<String> transactionBoundList(String value) {
        return new TransactionBoundList(value);
    }

    private static final class TransactionBoundList extends AbstractList<String> {
        private final String value;

        private TransactionBoundList(String value) {
            this.value = value;
        }

        @Override
        public String get(int index) {
            if (!TransactionSynchronizationManager.isActualTransactionActive()) {
                throw new IllegalStateException("Lazy collection accessed outside transaction");
            }
            if (index != 0) {
                throw new IndexOutOfBoundsException(index);
            }
            return value;
        }

        @Override
        public int size() {
            if (!TransactionSynchronizationManager.isActualTransactionActive()) {
                throw new IllegalStateException("Lazy collection accessed outside transaction");
            }
            return 1;
        }
    }

    private static final class TestTransactionManager extends AbstractPlatformTransactionManager {
        private boolean readOnly;

        private boolean isReadOnly() {
            return readOnly;
        }

        @Override
        protected Object doGetTransaction() {
            return new Object();
        }

        @Override
        protected void doBegin(Object transaction, TransactionDefinition definition) {
            readOnly = definition.isReadOnly();
        }

        @Override
        protected void doCommit(DefaultTransactionStatus status) {
        }

        @Override
        protected void doRollback(DefaultTransactionStatus status) {
        }
    }

    @Test
    void createRequest_ValidDescription_Success() {
        CreateMaintenanceRequest req = new CreateMaintenanceRequest();
        req.setRoomId(room.getId());
        req.setTitle("Leak problem");
        req.setDescription("Water is leaking from the sink loudly");
        req.setCategory(MaintenanceCategory.AIR_CONDITIONER);
        req.setPriority(MaintenancePriority.URGENT);
        req.setPreferredTimeSlots(List.of("Sáng (08:00 - 11:30)", "Cuối tuần (Thứ 7 - CN)"));
        
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
        assertEquals(MaintenanceCategory.AIR_CONDITIONER, result.getCategory());
        assertEquals(MaintenancePriority.URGENT, result.getPriority());
        assertEquals(req.getPreferredTimeSlots(), result.getPreferredTimeSlots());
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
        verify(maintenanceRepository).save(argThat(request -> request.getStatus() == MaintenanceStatus.ASSIGNED));
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
        verify(maintenanceRepository).save(argThat(request -> request.getStatus() == MaintenanceStatus.IN_PROGRESS));
    }

    @Test
    void submitWork_UsesStoredMaterialCostAndRequiresPayment() {
        sampleRequest.setStatus(MaintenanceStatus.IN_PROGRESS);
        sampleRequest.setCompletionImages(new ArrayList<>(List.of("completion.jpg")));
        sampleRequest.setMaterialCost(BigDecimal.valueOf(150000));
        when(maintenanceRepository.findById(requestId)).thenReturn(Optional.of(sampleRequest));
        when(maintenanceRepository.save(any(MaintenanceRequest.class))).thenAnswer(i -> i.getArgument(0));
        when(noteRepository.save(any(MaintenanceNote.class))).thenAnswer(i -> {
            MaintenanceNote note = i.getArgument(0);
            note.setId(UUID.randomUUID());
            return note;
        });

        MaintenanceRequest result = maintenanceService.submitWork(requestId, null);

        assertEquals(MaintenanceStatus.PENDING_PAYMENT, result.getStatus());
        assertEquals(BigDecimal.valueOf(150000), result.getMaterialCost());
    }

    @Test
    void submitWork_NoCharge_SkipsPayment() {
        sampleRequest.setStatus(MaintenanceStatus.IN_PROGRESS);
        sampleRequest.setCompletionImages(new ArrayList<>(List.of("completion.jpg")));
        sampleRequest.setMaterialCost(BigDecimal.ZERO);
        when(maintenanceRepository.findById(requestId)).thenReturn(Optional.of(sampleRequest));
        when(maintenanceRepository.save(any(MaintenanceRequest.class))).thenAnswer(i -> i.getArgument(0));
        when(noteRepository.save(any(MaintenanceNote.class))).thenAnswer(i -> {
            MaintenanceNote note = i.getArgument(0);
            note.setId(UUID.randomUUID());
            return note;
        });

        MaintenanceRequest result = maintenanceService.submitWork(requestId, null);

        assertEquals(MaintenanceStatus.PENDING_REVIEW, result.getStatus());
    }

    @Test
    void submitWork_WithoutCompletionImage_IsRejected() {
        sampleRequest.setStatus(MaintenanceStatus.IN_PROGRESS);
        sampleRequest.setCompletionImages(new ArrayList<>());
        when(maintenanceRepository.findById(requestId)).thenReturn(Optional.of(sampleRequest));

        assertThrows(BadRequestException.class, () -> maintenanceService.submitWork(requestId, null));
        verify(maintenanceRepository, never()).save(any());
    }

    @Test
    void setAttachmentVideo_PersistsVideoUrl() {
        when(maintenanceRepository.findById(requestId)).thenReturn(Optional.of(sampleRequest));
        when(maintenanceRepository.save(any(MaintenanceRequest.class))).thenAnswer(i -> i.getArgument(0));

        MaintenanceRequest result = maintenanceService.setAttachmentVideo(requestId, "https://storage/video.mp4");

        assertEquals("https://storage/video.mp4", result.getAttachmentVideo());
        verify(maintenanceRepository).save(sampleRequest);
    }

    @Test
    void cancel_ShortReason_ThrowsBadRequest() {
        assertThrows(BadRequestException.class, () -> maintenanceService.cancel(requestId, "short"));
        assertThrows(BadRequestException.class, () -> maintenanceService.cancel(requestId, "   "));
        assertThrows(BadRequestException.class, () -> maintenanceService.cancel(requestId, null));
        verify(maintenanceRepository, never()).save(any());
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
                MaintenanceMaterial.builder().id(UUID.randomUUID()).request(sampleRequest).totalPrice(BigDecimal.valueOf(150000)).isFreeInContract(false).build(),
                MaintenanceMaterial.builder().id(UUID.randomUUID()).request(sampleRequest).totalPrice(BigDecimal.valueOf(50000)).isFreeInContract(true).build()
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
        verify(maintenanceRepository).save(argThat(request -> BigDecimal.valueOf(150000).equals(request.getMaterialCost())));
    }
}
