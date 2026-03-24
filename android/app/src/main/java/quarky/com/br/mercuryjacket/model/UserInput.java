package quarky.com.br.mercuryjacket.model;

import java.io.Serializable;

public class UserInput implements Serializable {
    public Integer powerLevel;
    public Integer externalTemperature;

    public UserInput(Integer powerLevel,Integer externalTemperature)
    {
        this.powerLevel = powerLevel;
        this.externalTemperature = externalTemperature;
    }
}
