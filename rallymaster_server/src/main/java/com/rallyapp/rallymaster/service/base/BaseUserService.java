package com.rallyapp.rallymaster.service.base;


import com.rallyapp.rallymaster.dto.base.BaseUserDTO;
import java.util.List;

public interface BaseUserService<D extends BaseUserDTO, ID> extends EntityService<D, ID> {

	public D fetchByEmailAddress (String emailAddress);
}
