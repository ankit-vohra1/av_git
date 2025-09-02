'''
This program takes an English language word from user as input & gets the meaning from data.json file.
End program via /end.
'''

import json
import difflib
from difflib import get_close_matches

data = json.load(open("data.json"))

def translate(word):
    import pdb
    matching_word_list=get_close_matches(word.lower(),data.keys() ) #, cutoff=0.8)

    if word in data:
        return data[word]
    elif word.upper() in data:
        return data[word.upper()]    
    elif word.lower() in data:
        return data[word.lower()]
    elif word.capitalize() in data:
        return data[word.capitalize()]

    elif len(matching_word_list) > 0:
        yn = input('Do you mean %s ? FYI, Other Options are : %s.\nChoose any OR type N/n.... ' % (matching_word_list[0], matching_word_list))

        if yn == 'n' or yn == 'N' :
            return "TRY AGAIN !!!!!"  
        else:
            if yn in data:
                print('Word is: ' + yn)
                #print(translate(yn))
                return data[yn]
                #return None
            else:
                #pdb.set_trace()
                print(''.join(translate(yn)))
                #return 'Wrong choice or spelling... Try again !'
                #pass
    else:
        return "Word does not exist. Please try another."

while True:
    word = input("\nEnter the word or \\end to exit: ")
    if word == '\\end':
        exit()
    #print(translate(word.lower()))
    print(''.join(translate(word)))


