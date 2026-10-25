package com.rallyapp.rallymaster.entity.base;

import java.io.Serializable;

import java.util.Objects;

import jakarta.persistence.MappedSuperclass;

@MappedSuperclass
public abstract class AbstractBaseEntity
  implements Serializable
{
    
    protected abstract Object getKey ();
    
    @Override
	public int hashCode() {
		return Objects.hash(getKey());
	}
	
	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
			
		AbstractBaseEntity other = (AbstractBaseEntity) obj;
		return getKey().equals(other.getKey());
	}
}