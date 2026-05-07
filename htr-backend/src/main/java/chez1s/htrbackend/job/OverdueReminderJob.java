package chez1s.htrbackend.job;

import chez1s.htrbackend.service.InvoiceService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.quartz.Job;
import org.quartz.JobExecutionContext;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class OverdueReminderJob implements Job {

    private final InvoiceService invoiceService;

    @Override
    public void execute(JobExecutionContext context) {
        log.info("OverdueReminderJob running");
        invoiceService.markOverdue();
        log.info("OverdueReminderJob completed");
    }
}
