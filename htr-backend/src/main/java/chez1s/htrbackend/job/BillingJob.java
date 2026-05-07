package chez1s.htrbackend.job;

import chez1s.htrbackend.service.InvoiceService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.quartz.Job;
import org.quartz.JobExecutionContext;
import org.springframework.stereotype.Component;

import java.time.YearMonth;

@Component
@RequiredArgsConstructor
@Slf4j
public class BillingJob implements Job {

    private final InvoiceService invoiceService;

    @Override
    public void execute(JobExecutionContext context) {
        YearMonth current = YearMonth.now();
        log.info("BillingJob running for month: {}", current);
        invoiceService.generateAllForMonth(current);
        log.info("BillingJob completed for month: {}", current);
    }
}
