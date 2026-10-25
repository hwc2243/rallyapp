package com.rallyapp.rallymaster.service.event;

import org.springframework.context.ApplicationEventPublisher;

public final class SpringServiceEventBus implements ServiceEventBus {

  private final ApplicationEventPublisher publisher;

  public SpringServiceEventBus(ApplicationEventPublisher publisher) {
    this.publisher = publisher;
  }

  @Override
  public void publish(ServiceEvent event) {
    publisher.publishEvent(event);
  }
}
