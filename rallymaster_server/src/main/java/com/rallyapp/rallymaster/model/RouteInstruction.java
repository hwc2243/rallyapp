package com.rallyapp.rallymaster.model;

import com.rallyapp.rallymaster.model.base.BaseRouteInstruction;
import com.rallyapp.rallymaster.model.Route;
import com.rallyapp.rallymaster.model.RouteItem;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public interface RouteInstruction<ROUTE> extends RouteItem<ROUTE>, BaseRouteInstruction<ROUTE>
{ 
}
