package com.rallyapp.rallymaster.service.base;


import com.rallyapp.rallymaster.dto.base.BaseRallyDTO;
import java.time.LocalDate;
import java.util.List;

public interface BaseRallyService<D extends BaseRallyDTO, ID> extends EntityService<D, ID> {
}
