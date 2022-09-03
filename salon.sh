#! /bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ Salon Appointment Scheduler ~~~~~\n"

MAIN_MENU() {
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  echo "How may I help you?" 
  echo -e "\n1. New Appointment \n2. Cancel Appointment \n3. Exit"
  read MAIN_MENU_SELECTION

  case $MAIN_MENU_SELECTION in
    1) NEW_APPOINTMENT ;;
    2) CANCEL_APPOINTMENT ;;
    3) EXIT ;;
    *) MAIN_MENU "Please enter a valid option." ;;
  esac
}

NEW_APPOINTMENT(){
  #get available services
  AVAILABLE_SERVICES=$($PSQL "select service_id, INITCAP(name) as name from services;")
  
  # if no available services
  if [[ -z $AVAILABLE_SERVICES ]]
  then
    # send to main menu
    MAIN_MENU "Sorry, we don't have any services available right now."
  else
    # display available services
    echo -e "\nHere are the services we offer:"
    echo "$AVAILABLE_SERVICES" | while read SERVICE_ID BAR NAME
    do
      echo "$SERVICE_ID) $NAME."
    done

  #ask for input service
  echo -e "\nWhich one would you like to choose?"
  read SERVICE_ID_SELECTED

  #check if input service is numbers
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    # send to main menu
    NEW_APPOINTMENT "That is not a valid service."
  else
    # get service availability
    SERVICE_AVAILABILITY=$($PSQL "select name from services where service_id = $SERVICE_ID_SELECTED AND available = true")
    
    #if service does not exist
    if [[ -z $SERVICE_AVAILABILITY ]] 
    then
      #display services menu
      NEW_APPOINTMENT "That service does not exist."
    else
      #if service exists ask for phone
      echo -e "\nPlease enter your phone number in order to continue:"
      read CUSTOMER_PHONE

      #check if customer exists
      CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")

      #if phone number does not exist, create customer
      if [[ -z $CUSTOMER_NAME ]]
      then
        #get customers name
        echo -e "\nIt seems it's the first time you are booking with us, please enter your name:"
        read CUSTOMER_NAME

        # insert new customer
        INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')") 
      fi

      # get customer_id
      CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

      #get appointment time
      echo -e "\nPlease enter the time you'd like to get your $SERVICE_AVAILABILITY done:"
      read SERVICE_TIME

      # insert appointment
      INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED,'$SERVICE_TIME')")

      #check if appoint was created successfully
      if [[ -z $INSERT_APPOINTMENT_RESULT ]]
      then
        # send to main menu, display error
        MAIN_MENU "We are sorry, it seems that there was an error processing your request. Please try again."
      else
        # send to main menu
        MAIN_MENU "I have put you down for a $SERVICE_AVAILABILITY at $SERVICE_TIME, $CUSTOMER_NAME."
      fi
    fi
  fi
fi
}

CANCEL_APPOINTMENT() {
  # get customer info
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")

  # if not found
  if [[ -z $CUSTOMER_ID  ]]
  then
    # send to main menu
    MAIN_MENU "I could not find a record for that phone number."
  else
    # get customer's appointments
    CUSTOMER_APPOINTMENTS=$($PSQL "select appointment_id, s.name, time from appointments inner join customers c using(customer_id) inner join services s using(service_id) where customer_id = $CUSTOMER_ID  and cancelled = 'f'")

    # if no appointments
    if [[ -z $CUSTOMER_APPOINTMENTS  ]]
    then
      # send to main menu
      MAIN_MENU "You do not have any appointments."
    else
      # display appointments
      echo -e "\nHere are your appointments:"
      echo "$CUSTOMER_APPOINTMENTS" | while read APPOINTMENT_ID BAR SERVICE_NAME BAR SERVICE_TIME BAR CANCELLED
      do
        echo "Appointment #$APPOINTMENT_ID for $SERVICE_NAME at $SERVICE_TIME."
      done

      # ask for appointment to cancel
      echo -e "\nWhich one would you like to cancel?"
      read APPOINTMENT_ID_TO_CANCEL

      # if not a number
      if [[ ! $APPOINTMENT_ID_TO_CANCEL =~ ^[0-9]+$ ]]
      then
        # send to main menu
        MAIN_MENU "That is not a valid appointment number."
      else
        # check if input exists
        APPOINTMENT_ID=$($PSQL "SELECT appointment_id FROM appointments WHERE appointment_id = $APPOINTMENT_ID_TO_CANCEL")

        #if input does not exist
        if [[ -z $APPOINTMENT_ID ]]
        then
          # send to main menu
          MAIN_MENU "We could not find an appointment with the information you entered."
        else
          # update cancelled status
          RETURN_APPOINTMENT_RESULT=$($PSQL "UPDATE appointments SET cancelled = 't' WHERE appointment_id = $APPOINTMENT_ID")
                    
          # send to main menu
          MAIN_MENU "Your appointment has been cancelled."
        fi
      fi
    fi
  fi
}

EXIT(){
  echo -e "\nThank you for stopping in.\n"
}

MAIN_MENU
