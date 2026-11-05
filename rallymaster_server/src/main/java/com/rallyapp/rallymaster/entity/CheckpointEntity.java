package com.rallyapp.rallymaster.entity;


import com.rallyapp.rallymaster.entity.base.BaseCheckpointEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.model.Checkpoint;
import com.rallyapp.rallymaster.model.CheckpointCheckpointType;
import jakarta.persistence.Entity;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.io.Serializable;

@Entity(name="Checkpoint")
@Table(name="checkpoint")
public class CheckpointEntity
    extends BaseCheckpointEntity
    implements Checkpoint<RouteEntity>, Serializable
{
	public CheckpointEntity ()
	{
		super();
	}
	
    // Private constructor to force the use of the Builder
    private CheckpointEntity (Builder builder)
    {
        this.checkpointNumber = builder.checkpointNumber;
        this.checkpointType = builder.checkpointType;
        this.name = builder.name;
    }

    public static class Builder extends RouteItemEntity.Builder<Builder> {

        private Long checkpointNumber = null;
        private CheckpointCheckpointType checkpointType = null;
        private String name = null;

        public Builder checkpointNumber(Long checkpointNumber) {
            this.checkpointNumber = checkpointNumber;
            return this;
        }

        public Builder checkpointType(CheckpointCheckpointType checkpointType) {
            this.checkpointType = checkpointType;
            return this;
        }

        public Builder name(String name) {
            this.name = name;
            return this;
        }

        @Override
        protected Builder self() {
            return this;
        }

        /**
         * The build method creates and returns the immutable Entity object.
         */
        public CheckpointEntity build() {
            return new CheckpointEntity(this);
        }
    }
}
