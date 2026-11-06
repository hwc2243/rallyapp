package com.rallyapp.rallymaster.service.event;

public interface ServiceEventBus {
  void publish(ServiceEvent event);
}
