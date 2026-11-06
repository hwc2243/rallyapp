package com.rallyapp.rallymaster.entity;


import com.rallyapp.rallymaster.entity.base.BaseRouteInstructionEntity;
import com.rallyapp.rallymaster.entity.RouteEntity;
import com.rallyapp.rallymaster.model.RouteInstruction;
import jakarta.persistence.Entity;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.io.Serializable;

@Entity(name="RouteInstruction")
@Table(name="route_instruction")
public class RouteInstructionEntity
    extends BaseRouteInstructionEntity
    implements RouteInstruction<RouteEntity>, Serializable
{
	public RouteInstructionEntity ()
	{
		super();
	}
	
    // Private constructor to force the use of the Builder
    private RouteInstructionEntity (Builder builder)
    {
        this.instructionNumber = builder.instructionNumber;
        this.instructionText = builder.instructionText;
    }

    public static class Builder extends RouteItemEntity.Builder<Builder> {

        private Long instructionNumber = null;
        private String instructionText = null;

        public Builder instructionNumber(Long instructionNumber) {
            this.instructionNumber = instructionNumber;
            return this;
        }

        public Builder instructionText(String instructionText) {
            this.instructionText = instructionText;
            return this;
        }

        @Override
        protected Builder self() {
            return this;
        }

        /**
         * The build method creates and returns the immutable Entity object.
         */
        public RouteInstructionEntity build() {
            return new RouteInstructionEntity(this);
        }
    }
}
