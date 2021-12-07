function build_stoichiometric_matrix(model::Dict{Symbol,Any})

    try

        # get the reaction table -
        reaction_table = model[:reactions]
        reaction_id_array = reaction_table[!, :reaction_number]
        compound_id_array = model[:compounds][!,:compound_id]

        # now - let's build the stm -
        number_of_species = length(compound_id_array)
        number_of_reactions = length(reaction_id_array)
        stoichiometric_matrix = zeros(number_of_species, number_of_reactions)

        # build the array -
        for reaction_index = 1:number_of_reactions

            # what is my reaction id?
            reaction_id = reaction_id_array[reaction_index]

            # get row from the reaction table -
            df_reaction = filter(:reaction_number => x -> (x == reaction_id), reaction_table)

            # grab the stm dictionary -
            stm_dictionary = df_reaction[1, :stoichiometric_dictionary]

            # ok, lets see if we have these species -
            for species_index = 1:number_of_species

                # species code -
                species_symbol = compound_id_array[species_index]
                if (haskey(stm_dictionary, species_symbol) == true)
                    stm_coeff_value = stm_dictionary[species_symbol]
                    stoichiometric_matrix[species_index, reaction_index] = stm_coeff_value
                end
            end
        end

        # return -
        return (compound_id_array, reaction_id_array, stoichiometric_matrix)
    catch error

        # what is our error policy? => for now, just print the message
        error_message = sprint(showerror, error, catch_backtrace())
        println(error_message)

    end
end

function find_compound_index(model::Dict{Symbol,Any}, 
    search::Pair{Symbol,String})

    # get the compounds table -
    compounds_table = model[:compounds]

    # get list of compound names -
    tmp_array = compounds_table[!,search.first] |> collect
	
    # do we have this name? (if yes, then return index)
    return findfirst(x->x==search.second,tmp_array)
end

function find_reaction_index(model::Dict{Symbol,Any}, 
    search::Pair{Symbol,String})

    # get the compounds table -
    reaction_table = model[:reactions]

    # get list of compound names -
    tmp_array = reaction_table[!,search.first] |> collect
	
    # do we have this name? (if yes, then return index)
    return findfirst(x->x==search.second,tmp_array)
end

function update_flux_bounds_directionality(MODEL,default_flux_bounds)

    # get the ΔG table -> for now, just use the mean value -
    ΔG_table = MODEL[:ΔG]

    # how many reactions do we have ΔG data for?
    (number_of_reactions,_) = size(ΔG_table)
    for reaction_index = 1:number_of_reactions
        
        # get ΔG value -
        μ_ΔG_value = ΔG_table[reaction_index,:μ_ΔG]

        # get the corresponding reaction number -
        reaction_id = ΔG_table[reaction_index, :reaction_number]

        # what index is this?
        index_in_bounds_array = find_reaction_index(MODEL,:reaction_number=>reaction_id)
        if (isempty(index_in_bounds_array) == false)
            
            # backward?
            is_reversible = -1*(sign(μ_ΔG_value)) <= 0.0 ? true : false 
            if (is_reversible == false)
                default_flux_bounds[index_in_bounds_array,1] = 0.0
            end
        end
    end

    return default_flux_bounds
end