package chez1s.htrbackend.config;

import chez1s.htrbackend.job.BillingJob;
import chez1s.htrbackend.job.OverdueReminderJob;
import org.quartz.*;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class QuartzConfig {

    @Bean
    public JobDetail billingJobDetail() {
        return JobBuilder.newJob(BillingJob.class)
                .withIdentity("billingJob")
                .storeDurably()
                .build();
    }

    @Bean
    public Trigger billingTrigger(JobDetail billingJobDetail) {
        return TriggerBuilder.newTrigger()
                .forJob(billingJobDetail)
                .withIdentity("billingTrigger")
                .withSchedule(CronScheduleBuilder.cronSchedule("0 0 1 1 * ?"))
                .build();
    }

    @Bean
    public JobDetail overdueJobDetail() {
        return JobBuilder.newJob(OverdueReminderJob.class)
                .withIdentity("overdueJob")
                .storeDurably()
                .build();
    }

    @Bean
    public Trigger overdueTrigger(JobDetail overdueJobDetail) {
        return TriggerBuilder.newTrigger()
                .forJob(overdueJobDetail)
                .withIdentity("overdueTrigger")
                .withSchedule(CronScheduleBuilder.cronSchedule("0 0 8 * * ?"))
                .build();
    }
}
