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

    @unpack (NMod,Eff,PowMaxSegTurb,DisPointTurb) = HY
    @unpack (Head_upper,Head_lower,max_head) = Head

    S1_upper = 0
    S2_upper = 0
    S1_lower = 0
    S2_lower = 0
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

    # Upper reservoir

    for iMod = 1:HY.NMod

        if iMod == 1

            if Head_upper == max_head[1] 
                P_1_1[iMod] = HY.PowMaxSegTurb[iMod, 1]
                P_1_2[iMod] = HY.PowMaxSegTurb[iMod, 2]
                P_1_3[iMod] = HY.PowMaxSegTurb[iMod, 3]
                P_1_4[iMod] = HY.PowMaxSegTurb[iMod, 4]
                P_1_5[iMod] = HY.PowMaxSegTurb[iMod, 5]
                K_1[iMod] = HY.PowMaxSegTurb[iMod, 1]-HY.DisPointTurb[iMod, 1]*((HY.PowMaxSegTurb[iMod, 2]-HY.PowMaxSegTurb[iMod, 1])/(HY.DisPointTurb[iMod, 2]-HY.DisPointTurb[iMod, 1]))
                K_2[iMod] = HY.PowMaxSegTurb[iMod, 2]-HY.DisPointTurb[iMod, 2]*((HY.PowMaxSegTurb[iMod, 3]-HY.PowMaxSegTurb[iMod, 2])/(HY.DisPointTurb[iMod, 3]-HY.DisPointTurb[iMod, 2]))
                K_3[iMod] = HY.PowMaxSegTurb[iMod, 3]-HY.DisPointTurb[iMod, 3]*((HY.PowMaxSegTurb[iMod, 4]-HY.PowMaxSegTurb[iMod, 3])/(HY.DisPointTurb[iMod, 4]-HY.DisPointTurb[iMod, 3]))
                K_4[iMod] = HY.PowMaxSegTurb[iMod, 4]-HY.DisPointTurb[iMod, 4]*((HY.PowMaxSegTurb[1iMod, 5]-HY.PowMaxSegTurb[iMod, 4])/(HY.DisPointTurb[iMod, 5]-HY.DisPointTurb[iMod, 4]))
            else
                S1_upper = HY.Eff[1,1]
                eta = HY.Eff[1,1] / (max_head[1] * 9810)
                S2_upper = eta * 9810 * Head_upper
                P_1_1[iMod] = HY.PowMaxSegTurb[1, 1]
                P_2_1[iMod] = S2_upper * HY.DisPointTurb[1, 1]
                Delta_Power[1] = P_1_1[iMod] - P_2_1[iMod]
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
            if Head_lower == max_head[2] 
                P_1_1[iMod] = HY.PowMaxSegTurb[iMod, 1]
                P_1_2[iMod] = HY.PowMaxSegTurb[iMod, 2]
                P_1_3[iMod] = HY.PowMaxSegTurb[iMod, 3]
                P_1_4[iMod] = HY.PowMaxSegTurb[iMod, 4]
                P_1_5[iMod] = HY.PowMaxSegTurb[iMod, 5]
                K_1[iMod] = HY.PowMaxSegTurb[iMod, 1]-HY.DisPointTurb[iMod, 1]*((HY.PowMaxSegTurb[iMod, 2]-HY.PowMaxSegTurb[iMod, 1])/(HY.DisPointTurb[iMod, 2]-HY.DisPointTurb[iMod, 1]))
                K_2[iMod] = HY.PowMaxSegTurb[iMod, 2]-HY.DisPointTurb[iMod, 2]*((HY.PowMaxSegTurb[iMod, 3]-HY.PowMaxSegTurb[iMod, 2])/(HY.DisPointTurb[iMod, 3]-HY.DisPointTurb[iMod, 2]))
                K_3[iMod] = HY.PowMaxSegTurb[iMod, 3]-HY.DisPointTurb[iMod, 3]*((HY.PowMaxSegTurb[iMod, 4]-HY.PowMaxSegTurb[iMod, 3])/(HY.DisPointTurb[iMod, 4]-HY.DisPointTurb[iMod, 3]))
                K_4[iMod] = HY.PowMaxSegTurb[iMod, 4]-HY.DisPointTurb[iMod, 4]*((HY.PowMaxSegTurb[1iMod, 5]-HY.PowMaxSegTurb[iMod, 4])/(HY.DisPointTurb[iMod, 5]-HY.DisPointTurb[iMod, 4]))
            else 
                S1_lower = HY.Eff[2,1]
                eta = HY.Eff[2,1] / (max_head[2] * 9810)
                S2_lower = eta * 9810 * Head_lower
                P_1_1[iMod] = HY.PowMaxSegTurb[2, 1]
                P_2_1[iMod] = S2_upper * HY.DisPointTurb[2, 1]
                Delta_Power[1] = P_1_1[iMod] - P_2_1[iMod]
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
    
    return K_1, K_2, K_3, K_4

end 
