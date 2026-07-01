package chez1s.htrbackend.dto.response;

import java.util.List;

public record InvoiceGenerationResponse(
        String month,
        int activeContracts,
        int generated,
        int alreadyExists,
        int missingMeterReading,
        int missingFeeConfig,
        int failed,
        String message,
        List<String> details
) {
}
