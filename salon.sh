#! /bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ MY SALON ~~~~~"

echo -e "\nWelcome to My Salon, how can I help you?\n" 

MAIN_MENU(){
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  AVALIABLE_SERVICES=$($PSQL  "select service_id, name from services ORDER BY  service_id")
 
  if [[ -z $AVALIABLE_SERVICES ]]
  then
  echo "Sorry, we dont have any service available right now"
  else
  # display available services
  echo "$AVALIABLE_SERVICES" | while read SERVICE_ID BAR NAME
    do
      echo "$SERVICE_ID) $NAME"
    done

  #ask for input service
  read SERVICE_ID_SELECTED

  #check if input service is numbers
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    # send to main menu
    MAIN_MENU "That is not a valid service."
  else
    # get service availability
    SERVICE_AVAILABILITY=$($PSQL "SELECT service_id FROM services WHERE service_id = $SERVICE_ID_SELECTED ")
    SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED ")
    
    #if service does not exist
    if [[ -z $SERVICE_AVAILABILITY ]] 
    then
      #display services menu
      MAIN_MENU "I could not find that service. What would you like today?"
    else
      #if service exists ask for phone
      echo -e "\nWhat's your phone number?"
      read CUSTOMER_PHONE

      #check if customer exists
      CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")

    #if phone number does not exist, create customer
    if [[ -z $CUSTOMER_NAME ]]
    then
      #get customers name
      echo -e "\nI don't have a record for that phone number, what's your name?"
      read CUSTOMER_NAME
      # insert new customer
      INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')") 
    fi

    #get appointment time
    CUSTOMER_NAME_FORMATTED=$(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')
    echo -e "\nWhat time would you like your $(echo $SERVICE_NAME | sed -r 's/^ *| *$//g'), $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')?"
    read SERVICE_TIME

    # get customer_id
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

    if [[ $SERVICE_TIME ]]
    then
      # insert appointment
      INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED,'$SERVICE_TIME')")

      if [[ $INSERT_APPOINTMENT_RESULT ]]
      then
        echo -e "\nI have put you down for a $(echo $SERVICE_NAME | sed -r 's/^ *| *$//g') at $SERVICE_TIME, $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g').\n"
          fi
        fi
      fi
    fi
  fi
}

MAIN_MENU
