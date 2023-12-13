# Function used to calculate the head

function head_evaluation(
    case::caseData, 
    Reservoir,
    HY::HydroData,
    iScen,
    t,
    NStep
    )

    path=case.DataPath
    cd(path)
    f=open("Water_volumes_levels.dat")
    line=readline(f)

    line = readline(f)
    items = split(line, " ")
    NMod = parse(Int, items[1]) #set number of modules
    water_volumes_file=zeros(Float64,HY.NMod,21);
    water_levels_file=zeros(Float64,HY.NMod,21);
    max_head=zeros(Float64,HY.NMod);
    NVolumes=zeros(NMod);
  
    for iMod=1:NMod
        line = readline(f)
        items = split(line, " ")
        NVolumes[iMod] = parse(Int, items[1])
        for n=1:Int(NVolumes[iMod])                                   
        water_volumes_file[iMod,n]=parse(Float64,items[1+n])    
        end
    end
    water_volumes_file;

    for iLine = 1:2
        line = readline(f)
    end

    for iMod=1:NMod
        line = readline(f)
        items = split(line, " ")
        for n=1:Int(NVolumes[iMod])                                  
        water_levels_file[iMod,n]=parse(Float64,items[n])            
        end
    end
    water_levels_file;

    for iLine = 1:2
        line = readline(f)
    end

    for iMod=1:NMod
        line = readline(f)                              
        max_head[iMod]=parse(Float64, strip(line))            
    end
    max_head; 

    #EVALUATE THE WATER LEVELS, GIVEN THE WATER VOLUMES IN THE RESERVOIR
    Level = zeros(HY.NMod)
    Head_upper = 0
    Head_lower = 0
   
    # CALCULATES THE WATER LEVELS (m a.s.l) AND THE HEAD FROM THE VOLUME RESULTS
    
    for iMod=1:HY.NMod

        for n=1:Int(NVolumes[iMod])-1
            
            if iScen == 1
                if t == 1
                    if HY.ResInit0[iMod] == water_volumes_file[iMod,n]
                        Level[iMod] = water_levels_file[iMod,n]
                    elseif HY.ResInit0[iMod] > water_volumes_file[iMod,n] && HY.ResInit0[iMod] < water_volumes_file[iMod,n+1]
                        Level[iMod] =(water_levels_file[iMod,n+1]-water_levels_file[iMod,n])/(water_volumes_file[iMod,n+1]-water_volumes_file[iMod,n])*(HY.ResInit0[iMod]-water_volumes_file[iMod,n])+water_levels_file[iMod,n]
                    end

                    if HY.ResInit0[iMod] == water_volumes_file[iMod,Int(NVolumes[iMod])] 
                        Level[iMod] = water_levels_file[iMod,Int(NVolumes[iMod])]
                    end

                else        
                    if Reservoir[iMod,iScen,t-1,NStep] == water_volumes_file[iMod,n]
                        Level[iMod] = water_levels_file[iMod,n] 
                    elseif Reservoir[iMod,iScen,t-1,NStep]> water_volumes_file[iMod,n] && Reservoir[iMod,iScen,t-1,NStep]< water_volumes_file[iMod,n+1]
                        Level[iMod] = (water_levels_file[iMod,n+1]-water_levels_file[iMod,n])/(water_volumes_file[iMod,n+1]-water_volumes_file[iMod,n])*(Reservoir[iMod,iScen,t-1,NStep]-water_volumes_file[iMod,n])+water_levels_file[iMod,n]
                    end

                    if Reservoir[iMod,iScen,t-1,NStep] == water_volumes_file[iMod,Int(NVolumes[iMod])] 
                        Level[iMod] = water_levels_file[iMod,Int(NVolumes[iMod])]
                    end

                end
            else
                if t == 1
                    if Reservoir[iMod,iScen-1,end,NStep] == water_volumes_file[iMod,n]
                        Level[iMod] = water_levels_file[iMod,n]
                    elseif Reservoir[iMod,iScen-1,end,NStep]> water_volumes_file[iMod,n] && Reservoir[iMod,iScen-1,end,NStep]< water_volumes_file[iMod,n+1]
                        Level[iMod] = (water_levels_file[iMod,n+1]-water_levels_file[iMod,n])/(water_volumes_file[iMod,n+1]-water_volumes_file[iMod,n])*(Reservoir[iMod,iScen-1,end,NStep]-water_volumes_file[iMod,n])+water_levels_file[iMod,n]
                    end

                    if Reservoir[iMod,iScen-1,end,NStep] == water_volumes_file[iMod,Int(NVolumes[iMod])] 
                        Level[iMod] = water_levels_file[iMod,Int(NVolumes[iMod])]
                    end

                else
                    if Reservoir[iMod,iScen,t-1,NStep] == water_volumes_file[iMod,n]
                        Level[iMod] = water_levels_file[iMod,n]
                    elseif Reservoir[iMod,iScen,t-1,NStep]> water_volumes_file[iMod,n] && Reservoir[iMod,iScen,t-1,NStep]< water_volumes_file[iMod,n+1]
                        Level[iMod] = (water_levels_file[iMod,n+1]-water_levels_file[iMod,n])/(water_volumes_file[iMod,n+1]-water_volumes_file[iMod,n])*(Reservoir[iMod,iScen,t-1,NStep]-water_volumes_file[iMod,n])+water_levels_file[iMod,n] 
                    end

                    if Reservoir[iMod,iScen,t-1,NStep] == water_volumes_file[iMod,Int(NVolumes[iMod])] 
                        Level[iMod] = water_levels_file[iMod,Int(NVolumes[iMod])]
                    end

                end
            end

        end
    
    end

    Head_upper = Level[1] - Level[2]
    Head_lower = Level[2] - 520
    
    return Head_data(water_volumes_file,water_levels_file,NVolumes,Head_upper,Head_lower,max_head)

end


function efficiency_evaluation(HY::HydroData, Head::Head_data)

    @unpack (NMod,Eff,PowMaxSegTurb,DisPointTurb,PowMaxSegPump,DisPointPump) = HY
    @unpack (Head_upper,Head_lower,max_head) = Head

    S2_upper = 0
    S2_lower = 0
    S2_pump = 0
    P_1_1 = zeros(HY.NMod)
    P_1_2 = zeros(HY.NMod)
    P_1_3 = zeros(HY.NMod)
    P_1_4 = zeros(HY.NMod)
    P_1_5 = zeros(HY.NMod)
    P_2_1 = zeros(HY.NMod)
    P_2_2 = zeros(HY.NMod)
    P_2_3 = zeros(HY.NMod)
    P_2_4 = zeros(HY.NMod)
    P_2_5 = zeros(HY.NMod)
    K_1 = zeros(HY.NMod)
    K_2 = zeros(HY.NMod)
    K_3 = zeros(HY.NMod)
    K_4 = zeros(HY.NMod)
    Delta_Power = zeros(HY.NMod)
    Delta_Power_pump = 0

    P_1_1_pump = 0
    P_1_2_pump = 0
    P_2_1_pump = 0
    P_2_2_pump = 0
    K_pump = 0

    # Upper reservoir

    if Head_upper == max_head[1] 
        K_pump = HY.PowMaxSegPump[1]-HY.DisPointPump[1]*((HY.PowMaxSegPump[2]-HY.PowMaxSegPump[1])/(HY.DisPointPump[2]-HY.DisPointPump[1]))
    else
        eta_pump = (max_head[1] * 9810) / HY.EffPump[1]
        S2_pump = (9810 * Head_upper) / eta_pump 
        P_1_1_pump = HY.PowMaxSegPump[1]
        P_2_1_pump = S2_pump * HY.DisPointPump[1]
        Delta_Power_pump = P_1_1_pump - P_2_1_pump
        P_2_2_pump = HY.PowMaxSegPump[2] - Delta_Power_pump
        K_pump = P_2_1_pump-HY.DisPointPump[1]*((P_2_2_pump - P_2_1_pump)/(HY.DisPointPump[2]-HY.DisPointPump[1]))
    end

    for iMod = 1:HY.NMod

        if iMod == 1

            if Head_upper == max_head[iMod] 
                K_1[iMod] = HY.PowMaxSegTurb[iMod, 1]-HY.DisPointTurb[iMod, 1]*((HY.PowMaxSegTurb[iMod, 2]-HY.PowMaxSegTurb[iMod, 1])/(HY.DisPointTurb[iMod, 2]-HY.DisPointTurb[iMod, 1]))
                K_2[iMod] = HY.PowMaxSegTurb[iMod, 2]-HY.DisPointTurb[iMod, 2]*((HY.PowMaxSegTurb[iMod, 3]-HY.PowMaxSegTurb[iMod, 2])/(HY.DisPointTurb[iMod, 3]-HY.DisPointTurb[iMod, 2]))
                K_3[iMod] = HY.PowMaxSegTurb[iMod, 3]-HY.DisPointTurb[iMod, 3]*((HY.PowMaxSegTurb[iMod, 4]-HY.PowMaxSegTurb[iMod, 3])/(HY.DisPointTurb[iMod, 4]-HY.DisPointTurb[iMod, 3]))
                K_4[iMod] = HY.PowMaxSegTurb[iMod, 4]-HY.DisPointTurb[iMod, 4]*((HY.PowMaxSegTurb[iMod, 5]-HY.PowMaxSegTurb[iMod, 4])/(HY.DisPointTurb[iMod, 5]-HY.DisPointTurb[iMod, 4]))
            else
                eta = HY.Eff[iMod,1] / (max_head[iMod] * 9810)
                S2_upper = eta * 9810 * Head_upper
                P_1_1[iMod] = HY.PowMaxSegTurb[iMod, 1]
                P_2_1[iMod] = S2_upper * HY.DisPointTurb[iMod, 1]
                Delta_Power[iMod] = P_1_1[iMod] - P_2_1[iMod]
                P_2_2[iMod] = HY.PowMaxSegTurb[iMod, 2] - Delta_Power[iMod]
                P_2_3[iMod] = HY.PowMaxSegTurb[iMod, 3] - Delta_Power[iMod]
                P_2_4[iMod] = HY.PowMaxSegTurb[iMod, 4] - Delta_Power[iMod]
                P_2_5[iMod] = HY.PowMaxSegTurb[iMod, 5] - Delta_Power[iMod]
                K_1[iMod] = P_2_1[iMod]-HY.DisPointTurb[iMod, 1]*((P_2_2[iMod] - P_2_1[iMod])/(HY.DisPointTurb[iMod, 2]-HY.DisPointTurb[iMod, 1]))
                K_2[iMod] = P_2_2[iMod]-HY.DisPointTurb[iMod, 2]*((P_2_3[iMod] - P_2_2[iMod])/(HY.DisPointTurb[iMod, 3]-HY.DisPointTurb[iMod, 2]))
                K_3[iMod] = P_2_3[iMod]-HY.DisPointTurb[iMod, 3]*((P_2_4[iMod] - P_2_3[iMod])/(HY.DisPointTurb[iMod, 4]-HY.DisPointTurb[iMod, 3]))
                K_4[iMod] = P_2_4[iMod]-HY.DisPointTurb[iMod, 4]*((P_2_5[iMod] - P_2_4[iMod])/(HY.DisPointTurb[iMod, 5]-HY.DisPointTurb[iMod, 4]))
            end

    # Lower reservoir
    
        else
            if Head_lower == max_head[iMod] 
                K_1[iMod] = HY.PowMaxSegTurb[iMod, 1]-HY.DisPointTurb[iMod, 1]*((HY.PowMaxSegTurb[iMod, 2]-HY.PowMaxSegTurb[iMod, 1])/(HY.DisPointTurb[iMod, 2]-HY.DisPointTurb[iMod, 1]))
                K_2[iMod] = HY.PowMaxSegTurb[iMod, 2]-HY.DisPointTurb[iMod, 2]*((HY.PowMaxSegTurb[iMod, 3]-HY.PowMaxSegTurb[iMod, 2])/(HY.DisPointTurb[iMod, 3]-HY.DisPointTurb[iMod, 2]))
                K_3[iMod] = HY.PowMaxSegTurb[iMod, 3]-HY.DisPointTurb[iMod, 3]*((HY.PowMaxSegTurb[iMod, 4]-HY.PowMaxSegTurb[iMod, 3])/(HY.DisPointTurb[iMod, 4]-HY.DisPointTurb[iMod, 3]))
                K_4[iMod] = HY.PowMaxSegTurb[iMod, 4]-HY.DisPointTurb[iMod, 4]*((HY.PowMaxSegTurb[iMod, 5]-HY.PowMaxSegTurb[iMod, 4])/(HY.DisPointTurb[iMod, 5]-HY.DisPointTurb[iMod, 4]))
            else 
                eta = HY.Eff[iMod,1] / (max_head[iMod] * 9810)
                S2_lower = eta * 9810 * Head_lower
                P_1_1[iMod] = HY.PowMaxSegTurb[iMod, 1]
                P_2_1[iMod] = S2_upper * HY.DisPointTurb[iMod, 1]
                Delta_Power[iMod] = P_1_1[iMod] - P_2_1[iMod]
                P_2_2[iMod] = HY.PowMaxSegTurb[iMod, 2] - Delta_Power[iMod]
                P_2_3[iMod] = HY.PowMaxSegTurb[iMod, 3] - Delta_Power[iMod]
                P_2_4[iMod] = HY.PowMaxSegTurb[iMod, 4] - Delta_Power[iMod]
                P_2_5[iMod] = HY.PowMaxSegTurb[iMod, 5] - Delta_Power[iMod]
                K_1[iMod] = P_2_1[iMod]-HY.DisPointTurb[iMod, 1]*((P_2_2[iMod] - P_2_1[iMod])/(HY.DisPointTurb[iMod, 2]-HY.DisPointTurb[iMod, 1]))
                K_2[iMod] = P_2_2[iMod]-HY.DisPointTurb[iMod, 2]*((P_2_3[iMod] - P_2_2[iMod])/(HY.DisPointTurb[iMod, 3]-HY.DisPointTurb[iMod, 2]))
                K_3[iMod] = P_2_3[iMod]-HY.DisPointTurb[iMod, 3]*((P_2_4[iMod] - P_2_3[iMod])/(HY.DisPointTurb[iMod, 4]-HY.DisPointTurb[iMod, 3]))
                K_4[iMod] = P_2_4[iMod]-HY.DisPointTurb[iMod, 4]*((P_2_5[iMod] - P_2_4[iMod])/(HY.DisPointTurb[iMod, 5]-HY.DisPointTurb[iMod, 4]))
            end
        end    
    end
    
    return Coeff_data(K_1, K_2, K_3, K_4, K_pump)

end 
