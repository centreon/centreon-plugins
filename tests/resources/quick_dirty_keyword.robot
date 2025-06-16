*** Settings ***
Library    connector.py
Library    OperatingSystem
Library    String

*** Keywords ***
Execute Script Via Centreon Connector
    [Documentation]    Execute a Perl script via Centreon connector (quick and dirty)
    [Arguments]    ${script_path}    ${timeout}=10    ${cmd_id}=1
    
    # Nettoyer les fichiers précédents
    Remove File    /tmp/connector.output
    
    # Démarrer le connecteur
    Start Connector
    
    # Envoyer la commande
    Send To Connector    ${cmd_id}    ${timeout}    ${script_path}
    
    # Attendre la réponse (le connecteur Centreon peut prendre du temps)
    Sleep    3s
    
    # Vérifier qu'il y a une réponse
    ${output_exists}    Run Keyword And Return Status    File Should Exist    /tmp/connector.output
    
    ${result}    Create Dictionary    success=${False}    output=${EMPTY}    error=${EMPTY}
    
    IF    ${output_exists}
        ${raw_content}    Get File    /tmp/connector.output
        ${content_length}    Get Length    ${raw_content}
        
        IF    ${content_length} > 0
            # Nettoyer le contenu (enlever les caractères de contrôle du protocole Centreon)
            ${clean_content}    Clean Centreon Output    ${raw_content}
            
            # Vérifier si on trouve notre texte attendu
            ${script_name}    Get File Name    ${script_path}
            ${expected_text}    Set Variable If    '${script_name}' == 'connector.pl'    Hello from connector.pl    output
            
            ${found_expected}    Run Keyword And Return Status    Should Contain    ${clean_content}    ${expected_text}
            
            Set To Dictionary    ${result}    success=${found_expected}    output=${clean_content}
            
            IF    not ${found_expected}
                Set To Dictionary    ${result}    error=Expected text '${expected_text}' not found in output
            END
        ELSE
            Set To Dictionary    ${result}    error=Output file is empty
        END
    ELSE
        Set To Dictionary    ${result}    error=No output file created
    END
    
    # Arrêter le connecteur
    Stop Connector
    
    RETURN    ${result}

Clean Centreon Output
    [Documentation]    Clean the binary output from Centreon connector
    [Arguments]    ${raw_content}
    
    # Le connecteur Centreon retourne un format binaire:
    # [return_code][null][length][null][actual_output]
    
    # Méthode 1: Enlever les caractères de contrôle communs
    ${cleaned}    Replace String    ${raw_content}    \x00    ${SPACE}
    ${cleaned}    Replace String    ${cleaned}    \x01    ${SPACE}
    ${cleaned}    Replace String    ${cleaned}    \x02    ${SPACE}
    ${cleaned}    Replace String    ${cleaned}    \x03    ${SPACE}
    
    # Méthode 2: Garder seulement les caractères imprimables
    ${final_clean}    Set Variable    ${EMPTY}
    ${chars}    Split String To Characters    ${cleaned}
    
    FOR    ${char}    IN    @{chars}
        ${ascii_value}    Convert To Integer    ${char}    base=256    # Get ASCII value
        # Garder les caractères imprimables (32-126) et quelques autres (10=newline, 13=carriage return)
        ${is_printable}    Evaluate    32 <= ${ascii_value} <= 126 or ${ascii_value} in [10, 13]
        ${final_clean}    Set Variable If    ${is_printable}    ${final_clean}${char}    ${final_clean}
    EXCEPT
        # Si la conversion échoue, utiliser la version simplement nettoyée
        ${final_clean}    Set Variable    ${cleaned}
    END
    
    # Nettoyer les espaces multiples
    ${final_clean}    Replace String Using Regexp    ${final_clean}    \\s+    ${SPACE}
    ${final_clean}    Strip String    ${final_clean}
    
    RETURN    ${final_clean}

Get File Name
    [Documentation]    Extract filename from path
    [Arguments]    ${file_path}
    
    ${parts}    Split String    ${file_path}    /
    ${filename}    Set Variable    ${parts}[-1]
    
    RETURN    ${filename}

*** Test Cases ***
Test Quick And Dirty Execution
    [Documentation]    Test du keyword quick and dirty
    
    ${result}    Execute Script Via Centreon Connector    ./connector.pl
    
    Log    Execution result: ${result}
    
    Should Be True    ${result}[success]    Script execution failed: ${result}[error]
    Should Contain    ${result}[output]    Hello from connector.pl
    
    Log    SUCCESS: Script executed via Centreon connector
    Log    Output: ${result}[output]

Test Multiple Script Executions
    [Documentation]    Test d'exécution de plusieurs scripts
    
    # Test 1
    ${result1}    Execute Script Via Centreon Connector    ./connector.pl    timeout=5    cmd_id=100
    Should Be True    ${result1}[success]    First execution failed: ${result1}[error]
    
    # Test 2 (même script, ID différent)
    ${result2}    Execute Script Via Centreon Connector    ./connector.pl    timeout=5    cmd_id=101
    Should Be True    ${result2}[success]    Second execution failed: ${result2}[error]
    
    Log    Both executions successful!

Example Usage For Different Scripts
    [Documentation]    Exemple d'utilisation pour différents types de scripts
    
    # Pour connector.pl
    ${result}    Execute Script Via Centreon Connector    ./connector.pl
    Should Be True    ${result}[success]
    Log    connector.pl output: ${result}[output]
    
    # Pour d'autres scripts Perl (exemple)
    # ${result2}    Execute Script Via Centreon Connector    ./my_plugin.pl
    # Should Be True    ${result2}[success]
    # Log    my_plugin.pl output: ${result2}[output]
    
    # Vous pouvez facilement tester n'importe quel script Perl comme ça !